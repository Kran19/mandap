import { PrismaService } from '../../prisma.service.js';
import { PlansService } from './plans.service.js';
import type { PaymentProvider } from '../providers/payment-provider.interface.js';
export declare class OrdersService {
    private prisma;
    private plansService;
    private paymentProvider;
    constructor(prisma: PrismaService, plansService: PlansService, paymentProvider: PaymentProvider);
    createCheckoutOrder(organizationId: string, userId: string, planSlug: string, interval: 'monthly' | 'yearly'): Promise<{
        order: {
            items: {
                id: string;
                metadata: import("@prisma/client/runtime/library").JsonValue | null;
                description: string;
                orderId: string;
                totalAmount: import("@prisma/client/runtime/library").Decimal;
                quantity: number;
                unitAmount: import("@prisma/client/runtime/library").Decimal;
            }[];
        } & {
            id: string;
            status: import("@prisma/client").$Enums.OrderStatus;
            createdAt: Date;
            userId: string | null;
            updatedAt: Date;
            organizationId: string;
            currency: string;
            provider: string | null;
            orderNumber: string;
            subtotal: import("@prisma/client/runtime/library").Decimal;
            discountAmount: import("@prisma/client/runtime/library").Decimal;
            taxAmount: import("@prisma/client/runtime/library").Decimal;
            totalAmount: import("@prisma/client/runtime/library").Decimal;
            providerOrderId: string | null;
        };
        checkout: {
            providerOrderId: string;
            amount: number;
            currency: string;
            keyId: string | undefined;
        };
    }>;
}
