import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
import { SubscriptionsService } from './subscriptions.service.js';
import { SubscriptionStatus } from '@prisma/client';

@Injectable()
export class EntitlementService {
  constructor(
    private prisma: PrismaService,
    private subscriptionsService: SubscriptionsService
  ) {}

  /**
   * Retrieves the active subscription, handling lazy expiration of PAST_DUE subscriptions
   * if their grace period has ended.
   */
  private async getValidSubscription(organizationId: string) {
    const subscription = await this.prisma.subscription.findFirst({
      where: {
        organizationId,
        status: { in: [SubscriptionStatus.ACTIVE, SubscriptionStatus.PAST_DUE, SubscriptionStatus.TRIALING] },
      },
      include: { plan: { include: { features: true, limits: true } } },
    });

    if (!subscription) return null;

    if (subscription.status === SubscriptionStatus.PAST_DUE) {
      if (subscription.gracePeriodEndsAt && subscription.gracePeriodEndsAt < new Date()) {
        // Grace period expired, lazily expire the subscription
        await this.prisma.$transaction(async (tx) => {
          await this.subscriptionsService.expire(tx, subscription.id);
        });
        return null;
      }
    }

    return subscription;
  }

  async hasFeature(organizationId: string, featureKey: string): Promise<boolean> {
    const sub = await this.getValidSubscription(organizationId);
    if (!sub) return false;

    const feature = sub.plan.features.find(f => f.featureKey === featureKey);
    return feature ? feature.enabled : false;
  }

  async getLimit(organizationId: string, limitKey: string): Promise<number | null> {
    const sub = await this.getValidSubscription(organizationId);
    if (!sub) return null;

    const limit = sub.plan.limits.find(l => l.key === limitKey);
    return limit ? limit.value : null;
  }

  async getApplicationAccess(organizationId: string) {
    const sub = await this.getValidSubscription(organizationId);
    
    if (!sub) {
      return {
        applicationAccess: false,
        subscriptionStatus: null,
        planId: null,
        currentPeriodEndsAt: null,
        reason: 'No valid subscription found',
      };
    }

    const access = sub.status === SubscriptionStatus.ACTIVE || 
                   sub.status === SubscriptionStatus.TRIALING;

    return {
      applicationAccess: access,
      subscriptionStatus: sub.status,
      planId: sub.planId,
      currentPeriodEndsAt: sub.currentPeriodEnd,
      reason: access ? null : `Subscription is ${sub.status}`,
    };
  }
}
