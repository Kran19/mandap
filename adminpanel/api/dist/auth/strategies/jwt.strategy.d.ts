import { Strategy } from 'passport-jwt';
import { PrismaService } from '../../prisma.service.js';
import { TokenPayload } from '../auth.service.js';
declare const JwtStrategy_base: new (...args: [opt: import("passport-jwt").StrategyOptionsWithRequest] | [opt: import("passport-jwt").StrategyOptionsWithoutRequest]) => Strategy & {
    validate(...args: any[]): unknown;
};
export declare class JwtStrategy extends JwtStrategy_base {
    private prisma;
    constructor(prisma: PrismaService);
    validate(payload: TokenPayload): Promise<{
        email: string;
        firstName: string | null;
        lastName: string | null;
        phone: string | null;
        gender: string | null;
        aadhaarNumber: string | null;
        aadhaarFrontUrl: string | null;
        aadhaarBackUrl: string | null;
        id: string;
        passwordHash: string;
        status: import("@prisma/client").$Enums.UserStatus;
        emailVerifiedAt: Date | null;
        mobileVerifiedAt: Date | null;
        identityVerifiedAt: Date | null;
        lastLoginAt: Date | null;
        createdAt: Date;
        updatedAt: Date;
    }>;
}
export {};
