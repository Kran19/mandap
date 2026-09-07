import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma.service.js';
export declare class TrialEligibilityService {
    private configService;
    private prisma;
    private readonly hmacSecret;
    constructor(configService: ConfigService, prisma: PrismaService);
    normalizeEmail(email: string): string;
    normalizeMobile(mobile: string): string;
    hashIdentity(value: string): string;
    checkEligibility(emailNormalizedHash: string, mobileNormalizedHash: string | null, identityReferenceHash: string | null, paymentFingerprint: string | null): Promise<{
        eligible: boolean;
        reason?: string;
    }>;
}
