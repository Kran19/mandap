import { EntitlementService } from '../services/entitlement.service.js';
export declare class EntitlementController {
    private readonly entitlementService;
    constructor(entitlementService: EntitlementService);
    getEntitlement(organizationId: string): Promise<{
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
