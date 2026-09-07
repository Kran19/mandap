import { PrismaService } from '../prisma.service.js';
import { JwtService } from '@nestjs/jwt';
import { RegisterDto } from './dto/register.dto.js';
import { LoginDto } from './dto/login.dto.js';
import { RefreshDto } from './dto/refresh.dto.js';
export interface TokenPayload {
    sub: string;
}
export declare class AuthService {
    private prisma;
    private jwtService;
    constructor(prisma: PrismaService, jwtService: JwtService);
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
    logout(refreshToken: string): Promise<void>;
    private generateAuthResponse;
    private hashString;
    verifyEmail(userId: string, token: string): Promise<{
        success: boolean;
    }>;
    sendOtp(userId: string, phone: string): Promise<{
        success: boolean;
        message: string;
    }>;
    verifyOtp(userId: string, phone: string, code: string): Promise<{
        success: boolean;
    }>;
    verifyIdentity(userId: string, identityReference: string): Promise<{
        success: boolean;
        identityReference: string;
    }>;
}
