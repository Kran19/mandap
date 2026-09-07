import { PrismaService } from '../../prisma.service.js';
import type { PaymentProvider } from '../providers/payment-provider.interface.js';
export declare class RefundsService {
    private prisma;
    private paymentProvider;
    constructor(prisma: PrismaService, paymentProvider: PaymentProvider);
    createRefund(actorId: string, paymentId: string, amount: number, reason?: string): Promise<{
        id: string;
        status: string;
        createdAt: Date;
        updatedAt: Date;
        currency: string;
        amount: import("@prisma/client/runtime/library").Decimal;
        paymentId: string;
        providerRefundId: string | null;
        reason: string | null;
    }>;
}
