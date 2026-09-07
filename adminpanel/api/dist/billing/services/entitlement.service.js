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
import { PrismaService } from '../../prisma.service.js';
import { SubscriptionsService } from './subscriptions.service.js';
import { SubscriptionStatus } from '@prisma/client';
let EntitlementService = class EntitlementService {
    prisma;
    subscriptionsService;
    constructor(prisma, subscriptionsService) {
        this.prisma = prisma;
        this.subscriptionsService = subscriptionsService;
    }
    async getValidSubscription(organizationId) {
        const subscription = await this.prisma.subscription.findFirst({
            where: {
                organizationId,
                status: { in: [SubscriptionStatus.ACTIVE, SubscriptionStatus.PAST_DUE, SubscriptionStatus.TRIALING] },
            },
            include: { plan: { include: { features: true, limits: true } } },
        });
        if (!subscription)
            return null;
        if (subscription.status === SubscriptionStatus.PAST_DUE) {
            if (subscription.gracePeriodEndsAt && subscription.gracePeriodEndsAt < new Date()) {
                await this.prisma.$transaction(async (tx) => {
                    await this.subscriptionsService.expire(tx, subscription.id);
                });
                return null;
            }
        }
        return subscription;
    }
    async hasFeature(organizationId, featureKey) {
        const sub = await this.getValidSubscription(organizationId);
        if (!sub)
            return false;
        const feature = sub.plan.features.find(f => f.featureKey === featureKey);
        return feature ? feature.enabled : false;
    }
    async getLimit(organizationId, limitKey) {
        const sub = await this.getValidSubscription(organizationId);
        if (!sub)
            return null;
        const limit = sub.plan.limits.find(l => l.key === limitKey);
        return limit ? limit.value : null;
    }
    async getApplicationAccess(organizationId) {
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
};
EntitlementService = __decorate([
    Injectable(),
    __metadata("design:paramtypes", [PrismaService,
        SubscriptionsService])
], EntitlementService);
export { EntitlementService };
//# sourceMappingURL=entitlement.service.js.map