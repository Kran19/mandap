import { Controller, Post, Body, HttpCode, HttpStatus, Get, UseGuards } from '@nestjs/common';
import { AuthService } from './auth.service.js';
import { RegisterDto } from './dto/register.dto.js';
import { LoginDto } from './dto/login.dto.js';
import { RefreshDto } from './dto/refresh.dto.js';
import { VerifyEmailDto, SendOtpDto, VerifyOtpDto, VerifyIdentityDto } from './dto/verification.dto.js';
import { UseInterceptors, UploadedFile, ParseFilePipe, MaxFileSizeValidator, FileTypeValidator } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
// @ts-ignore
import { diskStorage } from 'multer';
import { extname } from 'path';
import { JwtAuthGuard } from './guards/jwt-auth.guard.js';
import { CurrentUser } from './decorators/current-user.decorator.js';
import type { User } from '@prisma/client';
import { ThrottlerGuard, Throttle, SkipThrottle } from '@nestjs/throttler';

import { PrismaService } from '../prisma.service.js';

@Controller('auth')
// Temporarily disabled throttling for development
// @UseGuards(ThrottlerGuard)
// @Throttle({ auth: { limit: 5, ttl: 900000 } })
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly prisma: PrismaService,
  ) {}

  @Post('register')
  register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Post('login/verify-otp')
  @HttpCode(HttpStatus.OK)
  verifyLoginOtp(@Body() dto: VerifyOtpDto) {
    return this.authService.verifyLoginOtp(dto.challengeId, dto.otp);
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  refresh(@Body() dto: RefreshDto) {
    return this.authService.refresh(dto);
  }

  @Post('logout')
  @HttpCode(HttpStatus.OK)
  logout(@Body() dto: RefreshDto) {
    return this.authService.logout(dto.refreshToken);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  async getMe(@CurrentUser() reqUser: User) {
    const user = await this.prisma.user.findUnique({
      where: { id: reqUser.id },
      include: { organizations: true },
    });
    if (!user) return null;

    return {
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      status: user.status,
      emailVerified: user.emailVerifiedAt != null,
      mobileVerified: user.mobileVerifiedAt != null,
      identityVerified: user.identityVerifiedAt != null,
      organizationId: user.organizations.length > 0 ? user.organizations[0].organizationId : null,
    };
  }

  @Post('email/verify')
  @UseGuards(JwtAuthGuard)
  verifyEmail(@CurrentUser() user: User, @Body() dto: VerifyEmailDto) {
    return this.authService.verifyEmail(user.id, dto.token);
  }

  @Post('mobile/send-otp')
  @UseGuards(JwtAuthGuard)
  sendOtp(@CurrentUser() user: User, @Body() dto: SendOtpDto) {
    return this.authService.sendOtp(user.id, dto.phone);
  }

  @Post('mobile/verify-otp')
  @UseGuards(JwtAuthGuard)
  verifyOtp(@CurrentUser() user: User, @Body() dto: VerifyOtpDto) {
    return this.authService.verifyOtp(user.id, dto.phone, dto.code);
  }

  @Post('identity/verify')
  @UseGuards(JwtAuthGuard)
  verifyIdentity(@CurrentUser() user: User, @Body() dto: VerifyIdentityDto) {
    return this.authService.verifyIdentity(user.id, dto.identityReference);
  }

  @Post('upload')
  @UseInterceptors(FileInterceptor('file', {
    storage: diskStorage({
      destination: './uploads',
      filename: (req: any, file: any, cb: any) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
        cb(null, `${file.fieldname}-${uniqueSuffix}${extname(file.originalname)}`);
      },
    }),
  }))
  uploadFile(@UploadedFile() file: any) {
    return { url: `/uploads/${file.filename}` };
  }
}
