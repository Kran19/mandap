import { Injectable, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
import { Prisma, SubscriptionStatus } from '@prisma/client';

@Injectable()
export class SubscriptionsService {
  constructor(private prisma: PrismaService) {}

  /**
   * Safe activation of a subscription from an order. Should be called inside a transaction.
   */
  async activateSubscription(
    tx: Prisma.TransactionClient,
    organizationId: string,
    planId: string,
    provider: string,
    providerSubscriptionId: string
  ) {
    // Check for existing subscription for this org
    let subscription = await tx.subscription.findFirst({
      where: { organizationId },
    });

    const now = new Date();
    // Default billing cycle to 1 month for simplicity, should derive from plan interval in reality
    const currentPeriodEnd = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000); 

    if (!subscription) {
      subscription = await tx.subscription.create({
        data: {
          organizationId,
          planId,
          provider,
          providerSubscriptionId,
          status: SubscriptionStatus.ACTIVE,
          currentPeriodStart: now,
          currentPeriodEnd: currentPeriodEnd,
        },
      });

      await this.createEvent(tx, subscription.id, 'ACTIVATED', null, SubscriptionStatus.ACTIVE);
    } else {
      const previousStatus = subscription.status;
      
      // Idempotency: already active for the same plan? No-op.
      // Wait, we need to handle renewals or plan changes.
      if (previousStatus === SubscriptionStatus.ACTIVE && subscription.planId === planId) {
        // Just renewing or duplicate activation
        subscription = await tx.subscription.update({
          where: { id: subscription.id },
          data: {
            currentPeriodStart: now,
            currentPeriodEnd: currentPeriodEnd,
          },
        });
        await this.createEvent(tx, subscription.id, 'RENEWED', previousStatus, SubscriptionStatus.ACTIVE);
      } else {
        // Plan change or reactivation from PAST_DUE / CANCELLED / EXPIRED
        subscription = await tx.subscription.update({
          where: { id: subscription.id },
          data: {
            planId,
            provider,
            providerSubscriptionId,
            status: SubscriptionStatus.ACTIVE,
            currentPeriodStart: now,
            currentPeriodEnd: currentPeriodEnd,
            gracePeriodEndsAt: null,
            cancelledAt: null,
          },
        });
        
        const eventType = previousStatus === SubscriptionStatus.PAST_DUE ? 'RECOVERED' : 'ACTIVATED';
        await this.createEvent(tx, subscription.id, eventType, previousStatus, SubscriptionStatus.ACTIVE);
      }
    }

    return subscription;
  }

  async markPastDue(
    tx: Prisma.TransactionClient,
    subscriptionId: string
  ) {
    const subscription = await tx.subscription.findUnique({ where: { id: subscriptionId } });
    if (!subscription) return null;

    if (subscription.status !== SubscriptionStatus.ACTIVE) {
      throw new ConflictException(`Cannot mark PAST_DUE from state ${subscription.status}`);
    }

    const now = new Date();
    // Give 7 days grace period
    const graceEnds = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

    const updated = await tx.subscription.update({
      where: { id: subscriptionId },
      data: {
        status: SubscriptionStatus.PAST_DUE,
        gracePeriodEndsAt: graceEnds,
      },
    });

    await this.createEvent(tx, subscription.id, 'PAYMENT_FAILED', SubscriptionStatus.ACTIVE, SubscriptionStatus.PAST_DUE);
    return updated;
  }

  async expire(
    tx: Prisma.TransactionClient,
    subscriptionId: string
  ) {
    const subscription = await tx.subscription.findUnique({ where: { id: subscriptionId } });
    if (!subscription) return null;

    if (subscription.status !== SubscriptionStatus.PAST_DUE) {
      throw new ConflictException(`Cannot EXPIRE from state ${subscription.status}`);
    }

    const updated = await tx.subscription.update({
      where: { id: subscriptionId },
      data: {
        status: SubscriptionStatus.EXPIRED,
      },
    });

    await this.createEvent(tx, subscription.id, 'EXPIRED', SubscriptionStatus.PAST_DUE, SubscriptionStatus.EXPIRED);
    return updated;
  }

  async cancel(
    tx: Prisma.TransactionClient,
    subscriptionId: string
  ) {
    const subscription = await tx.subscription.findUnique({ where: { id: subscriptionId } });
    if (!subscription) return null;

    if (subscription.status === SubscriptionStatus.CANCELLED || subscription.status === SubscriptionStatus.EXPIRED) {
      // Idempotent
      return subscription;
    }

    const previousStatus = subscription.status;
    const updated = await tx.subscription.update({
      where: { id: subscriptionId },
      data: {
        status: SubscriptionStatus.CANCELLED,
        cancelledAt: new Date(),
      },
    });

    await this.createEvent(tx, subscription.id, 'CANCELLED', previousStatus, SubscriptionStatus.CANCELLED);
    return updated;
  }

  async establishTrial(
    tx: Prisma.TransactionClient,
    providerSubscriptionId: string
  ) {
    const trialSetup = await tx.trialSetup.findUnique({
      where: { providerSubscriptionId },
      include: { user: true }
    });

    if (!trialSetup) {
      throw new ConflictException(`TrialSetup not found for provider subscription ${providerSubscriptionId}`);
    }

    if (trialSetup.status !== 'PENDING') {
      return null; // Idempotent or already handled
    }

    // Double check eligibility with proper null guards
    const conditions = [];
    if (trialSetup.emailNormalizedHash) conditions.push({ emailNormalizedHash: trialSetup.emailNormalizedHash });
    if (trialSetup.mobileNormalizedHash) conditions.push({ mobileNormalizedHash: trialSetup.mobileNormalizedHash });
    if (trialSetup.identityReferenceHash) conditions.push({ identityReferenceHash: trialSetup.identityReferenceHash });

    let existingClaim = null;
    if (conditions.length > 0) {
      existingClaim = await tx.trialClaim.findFirst({
        where: {
          OR: conditions,
        }
      });
    }

    if (existingClaim) {
      // If already claimed for this organization or user, ensure subscription is active and return
      let existingSub = await tx.subscription.findFirst({
        where: { organizationId: trialSetup.organizationId }
      });
      if (!existingSub) {
        const now = new Date();
        const trialEndsAt = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
        existingSub = await tx.subscription.create({
          data: {
            organizationId: trialSetup.organizationId,
            planId: trialSetup.planId,
            provider: 'RAZORPAY',
            providerSubscriptionId: providerSubscriptionId,
            status: SubscriptionStatus.TRIALING,
            currentPeriodStart: now,
            currentPeriodEnd: trialEndsAt,
          },
        });
      }
      await tx.trialSetup.update({
        where: { id: trialSetup.id },
        data: { status: 'ESTABLISHED' },
      });
      return existingSub;
    }

    const now = new Date();
    const trialEndsAt = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000); // 7 days

    // 1. Create the subscription in TRIALING state
    const subscription = await tx.subscription.create({
      data: {
        organizationId: trialSetup.organizationId,
        planId: trialSetup.planId,
        provider: 'RAZORPAY',
        providerSubscriptionId: providerSubscriptionId,
        status: SubscriptionStatus.TRIALING,
        currentPeriodStart: now,
        currentPeriodEnd: trialEndsAt,
      },
    });

    // 2. Create the permanent TrialClaim
    await tx.trialClaim.create({
      data: {
        userId: trialSetup.userId,
        organizationId: trialSetup.organizationId,
        trialPlanId: trialSetup.planId,
        subscriptionId: subscription.id,
        emailNormalizedHash: trialSetup.emailNormalizedHash,
        mobileNormalizedHash: trialSetup.mobileNormalizedHash,
        identityReferenceHash: trialSetup.identityReferenceHash,
        status: 'ESTABLISHED',
        startedAt: now,
        endsAt: trialEndsAt,
      }
    });

    // 3. Mark setup as completed
    await tx.trialSetup.update({
      where: { id: trialSetup.id },
      data: { status: 'COMPLETED' }
    });

    await this.createEvent(tx, subscription.id, 'TRIAL_ESTABLISHED', null, SubscriptionStatus.TRIALING);
    
    return subscription;
  }

  private async createEvent(
    tx: Prisma.TransactionClient,
    subscriptionId: string,
    eventType: string,
    previousStatus: string | null,
    newStatus: string
  ) {
    return tx.subscriptionEvent.create({
      data: {
        subscriptionId,
        eventType,
        previousStatus,
        newStatus,
      },
    });
  }
}
