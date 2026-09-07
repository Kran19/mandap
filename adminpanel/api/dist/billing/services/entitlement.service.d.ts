import { PrismaService } from '../../prisma.service.js';
import { SubscriptionsService } from './subscriptions.service.js';
export declare class EntitlementService {
    private prisma;
    private subscriptionsService;
    constructor(prisma: PrismaService, subscriptionsService: SubscriptionsService);
    private getValidSubscription;
    hasFeature(organizationId: string, featureKey: string): Promise<boolean>;
    getLimit(organizationId: string, limitKey: string): Promise<number | null>;
    getApplicationAccess(organizationId: string): Promise<{
        applicationAccess: boolean;
        subscriptionStatus: null;
        planId: null;
        currentPeriodEndsAt: null;
        reason: string;
    } | {
        applicationAccess: boolean;
        subscriptionStatus: import("@prisma/client").$Enums.SubscriptionStatus;
        planId: string;
        currentPeriodEndsAt: Date | null;
        reason: string | null;
    }>;
}
