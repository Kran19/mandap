import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma.service.js';
import * as crypto from 'crypto';

@Injectable()
export class TrialEligibilityService {
  private readonly hmacSecret: string;

  constructor(
    private configService: ConfigService,
    private prisma: PrismaService,
  ) {
    this.hmacSecret = this.configService.get<string>('TRIAL_HMAC_SECRET', 'dev_secret_do_not_use_in_prod');
  }

  public normalizeEmail(email: string): string {
    if (!email) return '';
    return email.trim().toLowerCase();
  }

  public normalizeMobile(mobile: string): string {
    if (!mobile) return '';
    // Basic E.164 normalization for Indian numbers (assuming +91 if length is 10)
    let cleaned = mobile.replace(/[^0-9+]/g, '');
    if (cleaned.length === 10) {
      cleaned = '+91' + cleaned;
    } else if (cleaned.startsWith('91') && cleaned.length === 12) {
      cleaned = '+' + cleaned;
    }
    return cleaned;
  }

  public hashIdentity(value: string): string {
    if (!value) return '';
    return crypto
      .createHmac('sha256', this.hmacSecret)
      .update(value)
      .digest('hex');
  }

  public async checkEligibility(
    emailNormalizedHash: string,
    mobileNormalizedHash: string | null,
    identityReferenceHash: string | null,
    paymentFingerprint: string | null
  ): Promise<{ eligible: boolean; reason?: string }> {
    // 1. Same verified identity -> REJECT
    if (identityReferenceHash) {
      const match = await this.prisma.trialClaim.findFirst({
        where: { identityReferenceHash },
      });
      if (match) return { eligible: false, reason: 'IDENTITY_ALREADY_USED' };
    }

    // 2. Same email -> REJECT
    if (emailNormalizedHash) {
      const match = await this.prisma.trialClaim.findFirst({
        where: { emailNormalizedHash },
      });
      if (match) return { eligible: false, reason: 'EMAIL_ALREADY_USED' };
    }

    // 3. Same mobile -> REJECT
    if (mobileNormalizedHash) {
      const match = await this.prisma.trialClaim.findFirst({
        where: { mobileNormalizedHash },
      });
      if (match) return { eligible: false, reason: 'MOBILE_ALREADY_USED' };
    }

    // 4. Same payment instrument -> REJECT (if we had it at eligibility check phase)
    if (paymentFingerprint) {
      const match = await this.prisma.trialClaim.findFirst({
        where: { paymentFingerprint },
      });
      if (match) return { eligible: false, reason: 'PAYMENT_INSTRUMENT_ALREADY_USED' };
    }

    return { eligible: true };
  }
}
