var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { Injectable, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
import { SubscriptionStatus } from '@prisma/client';
let SubscriptionsService = class SubscriptionsService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async activateSubscription(tx, organizationId, planId, provider, providerSubscriptionId) {
        let subscription = await tx.subscription.findFirst({
            where: { organizationId },
        });
        const now = new Date();
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
        }
        else {
            const previousStatus = subscription.status;
            if (previousStatus === SubscriptionStatus.ACTIVE && subscription.planId === planId) {
                subscription = await tx.subscription.update({
                    where: { id: subscription.id },
                    data: {
                        currentPeriodStart: now,
                        currentPeriodEnd: currentPeriodEnd,
                    },
                });
                await this.createEvent(tx, subscription.id, 'RENEWED', previousStatus, SubscriptionStatus.ACTIVE);
            }
            else {
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
    async markPastDue(tx, subscriptionId) {
        const subscription = await tx.subscription.findUnique({ where: { id: subscriptionId } });
        if (!subscription)
            return null;
        if (subscription.status !== SubscriptionStatus.ACTIVE) {
            throw new ConflictException(`Cannot mark PAST_DUE from state ${subscription.status}`);
        }
        const now = new Date();
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
    async expire(tx, subscriptionId) {
        const subscription = await tx.subscription.findUnique({ where: { id: subscriptionId } });
        if (!subscription)
            return null;
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
    async cancel(tx, subscriptionId) {
        const subscription = await tx.subscription.findUnique({ where: { id: subscriptionId } });
        if (!subscription)
            return null;
        if (subscription.status === SubscriptionStatus.CANCELLED || subscription.status === SubscriptionStatus.EXPIRED) {
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
    async establishTrial(tx, providerSubscriptionId) {
        const trialSetup = await tx.trialSetup.findUnique({
            where: { providerSubscriptionId },
            include: { user: true }
        });
        if (!trialSetup) {
            throw new ConflictException(`TrialSetup not found for provider subscription ${providerSubscriptionId}`);
        }
        if (trialSetup.status !== 'PENDING') {
            return null;
        }
        const conditions = [];
        if (trialSetup.emailNormalizedHash)
            conditions.push({ emailNormalizedHash: trialSetup.emailNormalizedHash });
        if (trialSetup.mobileNormalizedHash)
            conditions.push({ mobileNormalizedHash: trialSetup.mobileNormalizedHash });
        if (trialSetup.identityReferenceHash)
            conditions.push({ identityReferenceHash: trialSetup.identityReferenceHash });
        let existingClaim = null;
        if (conditions.length > 0) {
            existingClaim = await tx.trialClaim.findFirst({
                where: {
                    OR: conditions,
                }
            });
        }
        if (existingClaim) {
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
        const trialEndsAt = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
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
        await tx.trialSetup.update({
            where: { id: trialSetup.id },
            data: { status: 'COMPLETED' }
        });
        await this.createEvent(tx, subscription.id, 'TRIAL_ESTABLISHED', null, SubscriptionStatus.TRIALING);
        return subscription;
    }
    async createEvent(tx, subscriptionId, eventType, previousStatus, newStatus) {
        return tx.subscriptionEvent.create({
            data: {
                subscriptionId,
                eventType,
                previousStatus,
                newStatus,
            },
        });
    }
};
SubscriptionsService = __decorate([
    Injectable(),
    __metadata("design:paramtypes", [PrismaService])
], SubscriptionsService);
export { SubscriptionsService };
//# sourceMappingURL=subscriptions.service.js.map