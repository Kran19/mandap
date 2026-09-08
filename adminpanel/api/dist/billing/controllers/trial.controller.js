var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
var TrialController_1;
import { Controller, Post, Body, Param, UseGuards, Request, BadRequestException, ConflictException, Inject, Logger } from '@nestjs/common';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { OrgRoleGuard, RequireOrgRole } from '../../auth/guards/org-role.guard.js';
import { MembershipRole } from '@prisma/client';
import { TrialEligibilityService } from '../services/trial-eligibility.service.js';
import { PrismaService } from '../../prisma.service.js';
import * as crypto from 'crypto';
import { SubscriptionsService } from '../services/subscriptions.service.js';
let TrialController = TrialController_1 = class TrialController {
    trialEligibility;
    prisma;
    subscriptionsService;
    paymentProvider;
    logger = new Logger(TrialController_1.name);
    constructor(trialEligibility, prisma, subscriptionsService, paymentProvider) {
        this.trialEligibility = trialEligibility;
        this.prisma = prisma;
        this.subscriptionsService = subscriptionsService;
        this.paymentProvider = paymentProvider;
    }
    async setupTrial(req, organizationId, planId, identityReference, idempotencyKey) {
        try {
            if (!planId || !idempotencyKey || !identityReference) {
                throw new BadRequestException('planId, identityReference, and idempotencyKey are required');
            }
            const userId = req.user.id;
            const user = await this.prisma.user.findUnique({ where: { id: userId } });
            if (!user) {
                throw new BadRequestException('User not found');
            }
            if (!user.phone && !user.email) {
                throw new BadRequestException('Contact verification required');
            }
            const emailNormalizedHash = user.email ? this.trialEligibility.hashIdentity(this.trialEligibility.normalizeEmail(user.email)) : null;
            const mobileNormalizedHash = user.phone ? this.trialEligibility.hashIdentity(this.trialEligibility.normalizeMobile(user.phone)) : null;
            const identityReferenceHash = identityReference ? this.trialEligibility.hashIdentity(identityReference) : null;
            const eligibility = await this.trialEligibility.checkEligibility(emailNormalizedHash, mobileNormalizedHash, identityReferenceHash, null);
            if (!eligibility.eligible) {
                this.logger.warn(`Trial eligibility rejected: ${eligibility.reason}, allowing idempotent setup for user ${userId}`);
            }
            const endpoint = '/api/v1/billing/trial/setup';
            const requestPayloadString = JSON.stringify({ planId, identityReference });
            const requestHash = crypto.createHash('sha256').update(requestPayloadString).digest('hex');
            const idempotencyRecord = await this.prisma.idempotencyRecord.findUnique({
                where: {
                    organizationId_userId_endpoint_idempotencyKey: {
                        organizationId,
                        userId,
                        endpoint,
                        idempotencyKey,
                    }
                }
            });
            if (idempotencyRecord) {
                if (idempotencyRecord.requestHash !== requestHash) {
                    throw new ConflictException('Idempotency key used with different payload');
                }
                if (idempotencyRecord.responseStatus === 200) {
                    return idempotencyRecord.responseBody;
                }
                throw new ConflictException('Previous request failed or is still processing');
            }
            const plan = await this.prisma.plan.findUnique({
                where: { id: planId, status: 'ACTIVE' },
            });
            if (!plan) {
                throw new BadRequestException('Invalid plan');
            }
            const expiresAt = new Date();
            expiresAt.setHours(expiresAt.getHours() + 1);
            const trialStartAt = new Date();
            trialStartAt.setDate(trialStartAt.getDate() + 7);
            let providerSubscription;
            const providerPlanId = plan.monthlyProviderPlanId || 'plan_mock_monthly';
            if (this.paymentProvider?.createSubscription) {
                providerSubscription = await this.paymentProvider.createSubscription({
                    planId: providerPlanId,
                    totalCount: 1200,
                    startAt: trialStartAt,
                });
            }
            else {
                providerSubscription = {
                    id: 'sub_mock_' + Math.random().toString(36).substring(7),
                    status: 'created',
                    startAt: trialStartAt,
                };
            }
            const responseBody = await this.prisma.$transaction(async (tx) => {
                const setup = await tx.trialSetup.create({
                    data: {
                        userId,
                        organizationId,
                        planId,
                        emailNormalizedHash,
                        mobileNormalizedHash,
                        identityReferenceHash,
                        providerSubscriptionId: providerSubscription.id,
                        status: 'PENDING',
                        expiresAt,
                    }
                });
                const body = {
                    trialSetupId: setup.id,
                    providerSubscriptionId: providerSubscription.id,
                    status: 'PENDING_AUTHORIZATION',
                    trialStartAt,
                };
                await tx.idempotencyRecord.create({
                    data: {
                        organizationId,
                        userId,
                        endpoint,
                        idempotencyKey,
                        requestHash,
                        responseStatus: 200,
                        responseBody: body,
                        expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
                    }
                });
                await this.subscriptionsService.establishTrial(tx, providerSubscription.id);
                return body;
            });
            return responseBody;
        }
        catch (error) {
            console.error("SETUP TRIAL ERROR:", error);
            throw error;
        }
    }
};
__decorate([
    Post(':organizationId/setup'),
    UseGuards(OrgRoleGuard),
    RequireOrgRole(MembershipRole.OWNER),
    __param(0, Request()),
    __param(1, Param('organizationId')),
    __param(2, Body('planId')),
    __param(3, Body('identityReference')),
    __param(4, Body('idempotencyKey')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String, String, String]),
    __metadata("design:returntype", Promise)
], TrialController.prototype, "setupTrial", null);
TrialController = TrialController_1 = __decorate([
    Controller('billing/trial'),
    UseGuards(JwtAuthGuard),
    __param(3, Inject('PAYMENT_PROVIDER')),
    __metadata("design:paramtypes", [TrialEligibilityService,
        PrismaService,
        SubscriptionsService, Object])
], TrialController);
export { TrialController };
//# sourceMappingURL=trial.controller.js.map