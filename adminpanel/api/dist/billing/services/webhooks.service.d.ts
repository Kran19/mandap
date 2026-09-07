import { PrismaService } from '../../prisma.service.js';
import type { PaymentProvider } from '../providers/payment-provider.interface.js';
import { PaymentsService } from './payments.service.js';
import { SubscriptionsService } from './subscriptions.service.js';
export declare class WebhooksService {
    private prisma;
    private paymentsService;
    private subscriptionsService;
    private paymentProvider;
    private readonly logger;
    constructor(prisma: PrismaService, paymentsService: PaymentsService, subscriptionsService: SubscriptionsService, paymentProvider: PaymentProvider);
    processWebhook(signature: string, rawBody: Buffer, providerEventId: string, eventType: string): Promise<void>;
    private handleProviderEvent;
}
