import { OrdersService } from '../services/orders.service.js';
import { PaymentsService } from '../services/payments.service.js';
export declare class CheckoutController {
    private readonly ordersService;
    private readonly paymentsService;
    constructor(ordersService: OrdersService, paymentsService: PaymentsService);
    createCheckoutOrder(req: any, organizationId: string, planSlug: string, interval: 'monthly' | 'yearly'): Promise<{
        order: {
            items: {
                id: string;
                description: string;
                orderId: string;
                metadata: import("@prisma/client/runtime/library").JsonValue | null;
                totalAmount: import("@prisma/client/runtime/library").Decimal;
                quantity: number;
                unitAmount: import("@prisma/client/runtime/library").Decimal;
            }[];
        } & {
            id: string;
            status: import("@prisma/client").$Enums.OrderStatus;
            createdAt: Date;
            updatedAt: Date;
            userId: string | null;
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
    verifyPayment(organizationId: string, providerOrderId: string, providerPaymentId: string, signature: string): Promise<{
        success: boolean;
        payment: {
            id: string;
            status: import("@prisma/client").$Enums.PaymentStatus;
            createdAt: Date;
            updatedAt: Date;
            organizationId: string;
            currency: string;
            amount: import("@prisma/client/runtime/library").Decimal;
            orderId: string;
            provider: string;
            providerOrderId: string | null;
            providerPaymentId: string | null;
            paymentMethod: string | null;
            paidAt: Date | null;
            failureCode: string | null;
            failureMessage: string | null;
        };
    }>;
}
