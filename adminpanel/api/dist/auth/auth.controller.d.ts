import { AuthService } from './auth.service.js';
import { RegisterDto } from './dto/register.dto.js';
import { LoginDto } from './dto/login.dto.js';
import { RefreshDto } from './dto/refresh.dto.js';
import { VerifyEmailDto, SendOtpDto, VerifyOtpDto, VerifyIdentityDto } from './dto/verification.dto.js';
import type { User } from '@prisma/client';
import { PrismaService } from '../prisma.service.js';
export declare class AuthController {
    private readonly authService;
    private readonly prisma;
    constructor(authService: AuthService, prisma: PrismaService);
    register(dto: RegisterDto): Promise<{
        accessToken: string;
        refreshToken: string;
    }>;
    login(dto: LoginDto): Promise<{
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
        firstName: string | null;
        lastName: string | null;
        status: import("@prisma/client").$Enums.UserStatus;
        emailVerified: boolean;
        mobileVerified: boolean;
        identityVerified: boolean;
        organizationId: string | null;
    } | null>;
    verifyEmail(user: User, dto: VerifyEmailDto): Promise<{
        success: boolean;
    }>;
    sendOtp(user: User, dto: SendOtpDto): Promise<{
        success: boolean;
        message: string;
    }>;
    verifyOtp(user: User, dto: VerifyOtpDto): Promise<{
        success: boolean;
    }>;
    verifyIdentity(user: User, dto: VerifyIdentityDto): Promise<{
        success: boolean;
        identityReference: string;
    }>;
    uploadFile(file: any): {
        url: string;
    };
}
