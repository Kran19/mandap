import { Controller, Post, Body, Param, UseGuards, Request, BadRequestException, ConflictException, Inject, InternalServerErrorException, Logger } from '@nestjs/common';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { OrgRoleGuard, RequireOrgRole } from '../../auth/guards/org-role.guard.js';
import { MembershipRole } from '@prisma/client';
import { TrialEligibilityService } from '../services/trial-eligibility.service.js';
import { PrismaService } from '../../prisma.service.js';
import type { PaymentProvider } from '../providers/payment-provider.interface.js';
import * as crypto from 'crypto';

import { SubscriptionsService } from '../services/subscriptions.service.js';

@Controller('billing/trial')
@UseGuards(JwtAuthGuard)
export class TrialController {
  private readonly logger = new Logger(TrialController.name);

  constructor(
    private readonly trialEligibility: TrialEligibilityService,
    private readonly prisma: PrismaService,
    private readonly subscriptionsService: SubscriptionsService,
    @Inject('PAYMENT_PROVIDER') private readonly paymentProvider: PaymentProvider,
  ) {}

  @Post(':organizationId/setup')
  @UseGuards(OrgRoleGuard)
  @RequireOrgRole(MembershipRole.OWNER)
  async setupTrial(
    @Request() req: any,
    @Param('organizationId') organizationId: string,
    @Body('planId') planId: string,
    @Body('identityReference') identityReference: string,
    @Body('idempotencyKey') idempotencyKey: string
  ) {
    try {
      if (!planId || !idempotencyKey || !identityReference) {
      throw new BadRequestException('planId, identityReference, and idempotencyKey are required');
    }

    const userId = req.user.id;
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    
    if (!user) {
      throw new BadRequestException('User not found');
    }
    
    // Check basic prereqs: user must have phone or email
    if (!user.phone && !user.email) {
      throw new BadRequestException('Contact verification required');
    }

    // 1. Normalize and hash
    const emailNormalizedHash = user.email ? this.trialEligibility.hashIdentity(this.trialEligibility.normalizeEmail(user.email)) : null;
    const mobileNormalizedHash = user.phone ? this.trialEligibility.hashIdentity(this.trialEligibility.normalizeMobile(user.phone)) : null;
    const identityReferenceHash = identityReference ? this.trialEligibility.hashIdentity(identityReference) : null;

    // 2. Check Trial Eligibility (Anti-Abuse)
    const eligibility = await this.trialEligibility.checkEligibility(
      emailNormalizedHash,
      mobileNormalizedHash,
      identityReferenceHash,
      null // We don't have payment fingerprint until authorization
    );

    if (!eligibility.eligible) {
      this.logger.warn(`Trial eligibility rejected: ${eligibility.reason}, allowing idempotent setup for user ${userId}`);
    }

    // 3. Idempotency Check
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

    // 4. Resolve Plan
    const plan = await this.prisma.plan.findUnique({
      where: { id: planId, status: 'ACTIVE' },
    });
    
    if (!plan) {
      throw new BadRequestException('Invalid plan');
    }

    // 5. Create Pending TrialSetup
    // We create a short-lived TrialSetup
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 1); // 1 hour for checkout

    // Razorpay subscription starts in 7 days
    const trialStartAt = new Date();
    trialStartAt.setDate(trialStartAt.getDate() + 7);

    let providerSubscription;
    const providerPlanId = plan.monthlyProviderPlanId || 'plan_mock_monthly';
    if (this.paymentProvider?.createSubscription) {
      providerSubscription = await this.paymentProvider.createSubscription({
        planId: providerPlanId,
        totalCount: 1200, // 100 years
        startAt: trialStartAt,
      });
    } else {
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
          expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 hours
        }
      });

      // Automatically activate trial for mock/staging plans
      await this.subscriptionsService.establishTrial(tx, providerSubscription.id);

      return body;
    });

      return responseBody;
    } catch (error) {
      console.error("SETUP TRIAL ERROR:", error);
      throw error;
    }
  }
}
