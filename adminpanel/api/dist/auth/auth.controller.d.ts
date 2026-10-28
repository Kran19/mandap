import { AuthService } from './auth.service.js';
import { RegisterDto } from './dto/register.dto.js';
import { LoginDto } from './dto/login.dto.js';
import { RefreshDto } from './dto/refresh.dto.js';
import { VerifyEmailDto, SendOtpDto, VerifyOtpDto, VerifyIdentityDto } from './dto/verification.dto.js';
import { VerifyLoginOtpDto } from './dto/verify-otp.dto.js';
import type { User } from '@prisma/client';
import { PrismaService } from '../prisma.service.js';
export declare class AuthController {
    private readonly authService;
    private readonly prisma;
    constructor(authService: AuthService, prisma: PrismaService);
    register(dto: RegisterDto): Promise<{
        success: boolean;
        challengeId: string | undefined;
        message: string;
    }>;
    login(dto: LoginDto): Promise<{
        accessToken: string;
        refreshToken: string;
    } | {
        otpRequired: boolean;
        challengeId: string;
        phone: string;
        email: string | null;
    }>;
    verifyLoginOtp(dto: VerifyLoginOtpDto): Promise<{
        accessToken: string;
        refreshToken: string;
    }>;
    refresh(dto: RefreshDto): Promise<{
        accessToken: string;
        refreshToken: string;
    }>;
    logout(dto: RefreshDto): Promise<void>;
    getMe(reqUser: User): Promise<{
        id: string;
        email: string;
        firstName: string;
        lastName: string;
        status: import("@prisma/client").$Enums.UserStatus;
        emailVerified: boolean;
        mobileVerified: boolean;
        identityVerified: boolean;
        organizationId: string | null;
    } | null>;
    sendEmailCode(user: User): Promise<{
        success: boolean;
        message: string;
        challengeId: string;
    }>;
    verifyEmail(user: User, dto: VerifyEmailDto): Promise<{
        success: boolean;
        message: string;
    }>;
    sendOtp(user: User, dto: SendOtpDto): Promise<{
        success: boolean;
        message: string;
        challengeId: string;
    }>;
    verifyOtp(user: User, dto: VerifyOtpDto): Promise<{
        success: boolean;
        message: string;
    }>;
    verifyIdentity(user: User, dto: VerifyIdentityDto): Promise<{
        success: boolean;
        identityReference: string;
    }>;
    uploadFile(file: any): {
        url: string;
    };
}
