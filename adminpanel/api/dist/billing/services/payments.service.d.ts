import { PrismaService } from '../../prisma.service.js';
import type { PaymentProvider } from '../providers/payment-provider.interface.js';
import { SubscriptionsService } from './subscriptions.service.js';
import { Prisma } from '@prisma/client';
export declare class PaymentsService {
    private prisma;
    private subscriptionsService;
    private paymentProvider;
    private readonly logger;
    constructor(prisma: PrismaService, subscriptionsService: SubscriptionsService, paymentProvider: PaymentProvider);
    verifyClientPayment(providerOrderId: string, providerPaymentId: string, signature: string): Promise<{
        id: string;
        status: import("@prisma/client").$Enums.PaymentStatus;
        createdAt: Date;
        updatedAt: Date;
        organizationId: string;
        currency: string;
        amount: Prisma.Decimal;
        orderId: string;
        provider: string;
        providerOrderId: string | null;
        providerPaymentId: string | null;
        paymentMethod: string | null;
        paidAt: Date | null;
        failureCode: string | null;
        failureMessage: string | null;
    }>;
    finalizeCapturedPayment(providerOrderId: string, providerPaymentId: string): Promise<{
        id: string;
        status: import("@prisma/client").$Enums.PaymentStatus;
        createdAt: Date;
        updatedAt: Date;
        organizationId: string;
        currency: string;
        amount: Prisma.Decimal;
        orderId: string;
        provider: string;
        providerOrderId: string | null;
        providerPaymentId: string | null;
        paymentMethod: string | null;
        paidAt: Date | null;
        failureCode: string | null;
        failureMessage: string | null;
    }>;
    handlePaymentFailed(providerOrderId: string, providerPaymentId: string, errorCode: string, errorDescription: string): Promise<void>;
}
