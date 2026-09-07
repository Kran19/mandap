var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma.service.js';
import * as crypto from 'crypto';
let TrialEligibilityService = class TrialEligibilityService {
    configService;
    prisma;
    hmacSecret;
    constructor(configService, prisma) {
        this.configService = configService;
        this.prisma = prisma;
        this.hmacSecret = this.configService.get('TRIAL_HMAC_SECRET', 'dev_secret_do_not_use_in_prod');
    }
    normalizeEmail(email) {
        if (!email)
            return '';
        return email.trim().toLowerCase();
    }
    normalizeMobile(mobile) {
        if (!mobile)
            return '';
        let cleaned = mobile.replace(/[^0-9+]/g, '');
        if (cleaned.length === 10) {
            cleaned = '+91' + cleaned;
        }
        else if (cleaned.startsWith('91') && cleaned.length === 12) {
            cleaned = '+' + cleaned;
        }
        return cleaned;
    }
    hashIdentity(value) {
        if (!value)
            return '';
        return crypto
            .createHmac('sha256', this.hmacSecret)
            .update(value)
            .digest('hex');
    }
    async checkEligibility(emailNormalizedHash, mobileNormalizedHash, identityReferenceHash, paymentFingerprint) {
        if (identityReferenceHash) {
            const match = await this.prisma.trialClaim.findFirst({
                where: { identityReferenceHash },
            });
            if (match)
                return { eligible: false, reason: 'IDENTITY_ALREADY_USED' };
        }
        if (emailNormalizedHash) {
            const match = await this.prisma.trialClaim.findFirst({
                where: { emailNormalizedHash },
            });
            if (match)
                return { eligible: false, reason: 'EMAIL_ALREADY_USED' };
        }
        if (mobileNormalizedHash) {
            const match = await this.prisma.trialClaim.findFirst({
                where: { mobileNormalizedHash },
            });
            if (match)
                return { eligible: false, reason: 'MOBILE_ALREADY_USED' };
        }
        if (paymentFingerprint) {
            const match = await this.prisma.trialClaim.findFirst({
                where: { paymentFingerprint },
            });
            if (match)
                return { eligible: false, reason: 'PAYMENT_INSTRUMENT_ALREADY_USED' };
        }
        return { eligible: true };
    }
};
TrialEligibilityService = __decorate([
    Injectable(),
    __metadata("design:paramtypes", [ConfigService,
        PrismaService])
], TrialEligibilityService);
export { TrialEligibilityService };
//# sourceMappingURL=trial-eligibility.service.js.map