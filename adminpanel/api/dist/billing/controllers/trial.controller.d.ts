import { TrialEligibilityService } from '../services/trial-eligibility.service.js';
import { PrismaService } from '../../prisma.service.js';
import type { PaymentProvider } from '../providers/payment-provider.interface.js';
import { SubscriptionsService } from '../services/subscriptions.service.js';
export declare class TrialController {
    private readonly trialEligibility;
    private readonly prisma;
    private readonly subscriptionsService;
    private readonly paymentProvider;
    constructor(trialEligibility: TrialEligibilityService, prisma: PrismaService, subscriptionsService: SubscriptionsService, paymentProvider: PaymentProvider);
    setupTrial(req: any, organizationId: string, planId: string, identityReference: string, idempotencyKey: string): Promise<import("@prisma/client/runtime/library").JsonValue | {
        trialSetupId: string;
        providerSubscriptionId: string;
        status: string;
        trialStartAt: Date;
    }>;
}
