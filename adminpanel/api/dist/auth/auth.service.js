var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { Injectable, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma.service.js';
import { JwtService } from '@nestjs/jwt';
import * as argon2 from 'argon2';
import * as crypto from 'crypto';
import { UserStatus } from '@prisma/client';
import { normalizePhone } from '../utils/phone.util.js';
import { OtpService } from './otp.service.js';
let AuthService = class AuthService {
    prisma;
    jwtService;
    otpService;
    constructor(prisma, jwtService, otpService) {
        this.prisma = prisma;
        this.jwtService = jwtService;
        this.otpService = otpService;
    }
    async register(dto) {
        let email = dto.email?.trim().toLowerCase();
        const phone = normalizePhone(dto.phone);
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
                    slug: crypto.randomUUID(),
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
    async login(dto) {
        let user;
        if (dto.phone) {
            const phone = normalizePhone(dto.phone);
            user = await this.prisma.user.findUnique({ where: { phone } });
        }
        else if (dto.email) {
            const email = dto.email.trim().toLowerCase();
            user = await this.prisma.user.findUnique({ where: { email } });
        }
        else {
            throw new BadRequestException('Provide phone or email to login.');
        }
        if (!user || user.status !== UserStatus.ACTIVE) {
            throw new UnauthorizedException('Invalid credentials.');
        }
        const passwordMatches = await argon2.verify(user.passwordHash, dto.password);
        if (!passwordMatches) {
            throw new UnauthorizedException('Invalid credentials.');
        }
        if (user.phone) {
            const challengeId = await this.otpService.generateAndSendOtp(user.id, user.phone);
            return { otpRequired: true, challengeId };
        }
        else {
            await this.prisma.user.update({
                where: { id: user.id },
                data: { lastLoginAt: new Date() },
            });
            return this.generateAuthResponse(user.id);
        }
    }
    async verifyLoginOtp(challengeId, otp) {
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
    async refresh(dto) {
        let payload;
        try {
            payload = this.jwtService.verify(dto.refreshToken, {
                secret: process.env.JWT_REFRESH_SECRET,
            });
        }
        catch {
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
        if (session.revokedAt) {
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
        await this.prisma.refreshSession.update({
            where: { id: session.id },
            data: { revokedAt: new Date() },
        });
        return this.generateAuthResponse(userId, session.familyId);
    }
    async logout(refreshToken) {
        if (!refreshToken)
            return;
        const tokenHash = this.hashString(refreshToken);
        await this.prisma.refreshSession.updateMany({
            where: { tokenHash, revokedAt: null },
            data: { revokedAt: new Date() },
        });
    }
    async generateAuthResponse(userId, familyId) {
        const payload = { sub: userId };
        const accessToken = this.jwtService.sign(payload, {
            secret: process.env.JWT_ACCESS_SECRET,
            expiresIn: process.env.JWT_ACCESS_EXPIRES_IN || '15m',
        });
        const refreshToken = this.jwtService.sign({ ...payload, jti: crypto.randomUUID() }, {
            secret: process.env.JWT_REFRESH_SECRET,
            expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
        });
        const tokenHash = this.hashString(refreshToken);
        const newFamilyId = familyId || crypto.randomUUID();
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
    hashString(data) {
        return crypto.createHash('sha256').update(data).digest('hex');
    }
    async verifyEmail(userId, token) {
        await this.prisma.user.update({
            where: { id: userId },
            data: { emailVerifiedAt: new Date() },
        });
        return { success: true };
    }
    async sendOtp(userId, phone) {
        await this.prisma.user.update({
            where: { id: userId },
            data: { phone },
        });
        return { success: true, message: 'OTP sent to mobile (mock)' };
    }
    async verifyOtp(userId, phone, code) {
        if (code !== '123456') {
            throw new BadRequestException('Invalid OTP');
        }
        await this.prisma.user.update({
            where: { id: userId },
            data: { mobileVerifiedAt: new Date() },
        });
        return { success: true };
    }
    async verifyIdentity(userId, identityReference) {
        await this.prisma.user.update({
            where: { id: userId },
            data: { identityVerifiedAt: new Date() },
        });
        return { success: true, identityReference };
    }
};
AuthService = __decorate([
    Injectable(),
    __metadata("design:paramtypes", [PrismaService,
        JwtService,
        OtpService])
], AuthService);
export { AuthService };
//# sourceMappingURL=auth.service.js.map