import { Injectable, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma.service.js';
import { JwtService } from '@nestjs/jwt';
import { RegisterDto } from './dto/register.dto.js';
import { LoginDto } from './dto/login.dto.js';
import { RefreshDto } from './dto/refresh.dto.js';
import * as argon2 from 'argon2';
import * as crypto from 'crypto';
import { UserStatus } from '@prisma/client';
import { normalizePhone } from '../utils/phone.util.js';
import { OtpService } from './otp.service.js';

export interface TokenPayload {
  sub: string;
}

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private otpService: OtpService,
  ) {}

  async register(dto: RegisterDto) {
    let email = dto.email?.trim().toLowerCase();
    const phone = normalizePhone(dto.phone!);

    if (email) {
      const existingEmail = await this.prisma.user.findUnique({ where: { email } });
      if (existingEmail) {
        throw new BadRequestException('Email already in use.');
      }
    }

    const existingPhone = await this.prisma.user.findUnique({ where: { phone } });
    if (existingPhone) {
      throw new BadRequestException('Phone number already in use.');
    }

    const passwordHash = await argon2.hash(dto.password);
    
    const user = await this.prisma.$transaction(async (tx) => {
      const u = await tx.user.create({
        data: {
          email,
          passwordHash,
          firstName: dto.firstName,
          lastName: dto.lastName,
          phone,
          gender: dto.gender,
          aadhaarNumber: dto.aadhaarNumber,
          aadhaarFrontUrl: dto.aadhaarFrontUrl,
          aadhaarBackUrl: dto.aadhaarBackUrl,
        },
      });

      const orgName = email ? `${email.split('@')[0]}'s Workspace` : `Workspace ${u.id.substring(0, 8)}`;
      const org = await tx.organization.create({
        data: {
          name: orgName,
          slug: crypto.randomUUID(), // unique slug
        }
      });

      await tx.organizationMember.create({
        data: {
          userId: u.id,
          organizationId: org.id,
          role: 'OWNER',
        }
      });

      return u;
    });

    return { success: true, message: 'User registered successfully. Please login to verify phone.' };
  }

  async login(dto: LoginDto) {
    let user;
    
    if (dto.phone) {
      const phone = normalizePhone(dto.phone);
      user = await this.prisma.user.findUnique({ where: { phone } });
    } else if (dto.email) {
      const email = dto.email.trim().toLowerCase();
      user = await this.prisma.user.findUnique({ where: { email } });
    } else {
      throw new BadRequestException('Provide phone or email to login.');
    }

    if (!user || user.status !== UserStatus.ACTIVE) {
      // Do not reveal whether account exists vs bad password/status
      throw new UnauthorizedException('Invalid credentials.');
    }

    const passwordMatches = await argon2.verify(user.passwordHash, dto.password);
    if (!passwordMatches) {
      throw new UnauthorizedException('Invalid credentials.');
    }

    if (user.phone) {
      // New phone flow
      const challengeId = await this.otpService.generateAndSendOtp(user.id, user.phone);
      return { otpRequired: true, challengeId };
    } else {
      // Existing email-only users can still login, but should be prompted by frontend to migrate
      await this.prisma.user.update({
        where: { id: user.id },
        data: { lastLoginAt: new Date() },
      });
      return this.generateAuthResponse(user.id);
    }
  }

  async verifyLoginOtp(challengeId: string, otp: string) {
    const userId = await this.otpService.verifyOtp(challengeId, otp);
    
    await this.prisma.user.update({
      where: { id: userId },
      data: { 
        lastLoginAt: new Date(),
        mobileVerifiedAt: new Date(), 
      },
    });

    return this.generateAuthResponse(userId);
  }

  async refresh(dto: RefreshDto) {
    let payload: any;
    try {
      payload = this.jwtService.verify(dto.refreshToken, {
        secret: process.env.JWT_REFRESH_SECRET,
      });
    } catch {
      throw new UnauthorizedException('Invalid refresh token.');
    }

    const userId = payload.sub;
    const tokenHash = this.hashString(dto.refreshToken);

    const session = await this.prisma.refreshSession.findUnique({
      where: { tokenHash },
    });

    if (!session) {
      throw new UnauthorizedException('Invalid refresh token.');
    }

    // Reuse detection
    if (session.revokedAt) {
      // Token was already revoked, someone is trying to reuse it!
      // Invalidate the entire family chain to protect the user
      await this.prisma.refreshSession.updateMany({
        where: { familyId: session.familyId, revokedAt: null },
        data: { revokedAt: new Date() },
      });
      throw new UnauthorizedException('Token reuse detected. All sessions revoked.');
    }

    if (session.expiresAt < new Date()) {
      throw new UnauthorizedException('Refresh token expired.');
    }

    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user || user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException('User account is inactive.');
    }

    // Revoke current session
    await this.prisma.refreshSession.update({
      where: { id: session.id },
      data: { revokedAt: new Date() },
    });

    // Generate new tokens and link to same family
    return this.generateAuthResponse(userId, session.familyId);
  }

  async logout(refreshToken: string) {
    if (!refreshToken) return;
    
    const tokenHash = this.hashString(refreshToken);
    await this.prisma.refreshSession.updateMany({
      where: { tokenHash, revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }

  private async generateAuthResponse(userId: string, familyId?: string) {
    const payload: TokenPayload = { sub: userId };

    const accessToken = this.jwtService.sign(payload, {
      secret: process.env.JWT_ACCESS_SECRET,
      expiresIn: process.env.JWT_ACCESS_EXPIRES_IN || '15m',
    } as any);

    const refreshToken = this.jwtService.sign({ ...payload, jti: crypto.randomUUID() }, {
      secret: process.env.JWT_REFRESH_SECRET,
      expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
    } as any);

    const tokenHash = this.hashString(refreshToken);
    const newFamilyId = familyId || crypto.randomUUID();

    // 7 days from now
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    await this.prisma.refreshSession.create({
      data: {
        userId,
        tokenHash,
        familyId: newFamilyId,
        expiresAt,
      },
    });

    return {
      accessToken,
      refreshToken,
    };
  }

  private hashString(data: string): string {
    return crypto.createHash('sha256').update(data).digest('hex');
  }

  // --- Verification Stubs ---

  async verifyEmail(userId: string, token: string) {
    // In a real app, verify the token against a database record.
    // For now, we just mark the user's email as verified.
    await this.prisma.user.update({
      where: { id: userId },
      data: { emailVerifiedAt: new Date() },
    });
    return { success: true };
  }

  async sendOtp(userId: string, phone: string) {
    // In a real app, integrate with an SMS provider (e.g., Twilio, AWS SNS)
    // For now, just save the phone number to the user and return success.
    await this.prisma.user.update({
      where: { id: userId },
      data: { phone },
    });
    return { success: true, message: 'OTP sent to mobile (mock)' };
  }

  async verifyOtp(userId: string, phone: string, code: string) {
    // In a real app, verify the code. Here we just accept '123456'.
    if (code !== '123456') {
      throw new BadRequestException('Invalid OTP');
    }
    // Set mobileVerifiedAt
    await this.prisma.user.update({
      where: { id: userId },
      data: { mobileVerifiedAt: new Date() },
    });
    return { success: true };
  }

  async verifyIdentity(userId: string, identityReference: string) {
    // In a real app, call a UIDAI-compliant identity verification service.
    // For now, we mock success and persist the verified timestamp.
    await this.prisma.user.update({
      where: { id: userId },
      data: { identityVerifiedAt: new Date() },
    });
    return { success: true, identityReference };
  }
}
