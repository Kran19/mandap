import { AdminBillingService } from '../services/admin-billing.service.js';
import { AdminBillingQueryDto, AdminRefundDto } from '../dto/admin-billing.dto.js';
export declare class AdminBillingController {
    private readonly adminBillingService;
    constructor(adminBillingService: AdminBillingService);
    findAllSubscriptions(req: any, query: AdminBillingQueryDto): Promise<{
        data: ({
            organization: {
                name: string;
                id: string;
                status: import("@prisma/client").$Enums.OrganizationStatus;
                createdAt: Date;
                updatedAt: Date;
                slug: string;
            };
            plan: {
                name: string;
                id: string;
                status: string;
                createdAt: Date;
                updatedAt: Date;
                slug: string;
                description: string | null;
                monthlyPrice: import("@prisma/client/runtime/library").Decimal;
                yearlyPrice: import("@prisma/client/runtime/library").Decimal;
                currency: string;
                monthlyProviderPlanId: string | null;
                yearlyProviderPlanId: string | null;
            };
        } & {
            id: string;
            status: import("@prisma/client").$Enums.SubscriptionStatus;
            createdAt: Date;
            updatedAt: Date;
            organizationId: string;
            planId: string;
            provider: string;
            providerSubscriptionId: string | null;
            billingStatus: string | null;
            accessStatus: string | null;
            currentPeriodStart: Date | null;
            currentPeriodEnd: Date | null;
            gracePeriodEndsAt: Date | null;
            cancelledAt: Date | null;
        })[];
        meta: {
            total: number;
            page: number | undefined;
            limit: number | undefined;
        };
    }>;
    findOneSubscription(req: any, id: string): Promise<{
        organization: {
            name: string;
            id: string;
            status: import("@prisma/client").$Enums.OrganizationStatus;
            createdAt: Date;
            updatedAt: Date;
            slug: string;
        };
        plan: {
            name: string;
            id: string;
            status: string;
            createdAt: Date;
            updatedAt: Date;
            slug: string;
            description: string | null;
            monthlyPrice: import("@prisma/client/runtime/library").Decimal;
            yearlyPrice: import("@prisma/client/runtime/library").Decimal;
            currency: string;
            monthlyProviderPlanId: string | null;
            yearlyProviderPlanId: string | null;
        };
        events: {
            id: string;
            createdAt: Date;
            eventType: string;
            previousStatus: string | null;
            newStatus: string | null;
            metadata: import("@prisma/client/runtime/library").JsonValue | null;
            subscriptionId: string;
        }[];
    } & {
        id: string;
        status: import("@prisma/client").$Enums.SubscriptionStatus;
        createdAt: Date;
        updatedAt: Date;
        organizationId: string;
        planId: string;
        provider: string;
        providerSubscriptionId: string | null;
        billingStatus: string | null;
        accessStatus: string | null;
        currentPeriodStart: Date | null;
        currentPeriodEnd: Date | null;
        gracePeriodEndsAt: Date | null;
        cancelledAt: Date | null;
    }>;
    findAllOrders(req: any, query: AdminBillingQueryDto): Promise<{
        data: ({
            user: {
                email: string | null;
                firstName: string | null;
                lastName: string | null;
                phone: string | null;
                gender: string | null;
                aadhaarNumber: string | null;
                aadhaarFrontUrl: string | null;
                aadhaarBackUrl: string | null;
                id: string;
                passwordHash: string;
                status: import("@prisma/client").$Enums.UserStatus;
                emailVerifiedAt: Date | null;
                mobileVerifiedAt: Date | null;
                identityVerifiedAt: Date | null;
                lastLoginAt: Date | null;
                createdAt: Date;
                updatedAt: Date;
            } | null;
            organization: {
                name: string;
                id: string;
                status: import("@prisma/client").$Enums.OrganizationStatus;
                createdAt: Date;
                updatedAt: Date;
                slug: string;
            };
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
        })[];
        meta: {
            total: number;
            page: number | undefined;
            limit: number | undefined;
        };
    }>;
    findOneOrder(req: any, id: string): Promise<{
        user: {
            email: string | null;
            firstName: string | null;
            lastName: string | null;
            phone: string | null;
            gender: string | null;
            aadhaarNumber: string | null;
            aadhaarFrontUrl: string | null;
            aadhaarBackUrl: string | null;
            id: string;
            passwordHash: string;
            status: import("@prisma/client").$Enums.UserStatus;
            emailVerifiedAt: Date | null;
            mobileVerifiedAt: Date | null;
            identityVerifiedAt: Date | null;
            lastLoginAt: Date | null;
            createdAt: Date;
            updatedAt: Date;
        } | null;
        organization: {
            name: string;
            id: string;
            status: import("@prisma/client").$Enums.OrganizationStatus;
            createdAt: Date;
            updatedAt: Date;
            slug: string;
        };
        payments: {
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
        }[];
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
    }>;
    findAllPayments(req: any, query: AdminBillingQueryDto): Promise<{
        data: ({
            organization: {
                name: string;
                id: string;
                status: import("@prisma/client").$Enums.OrganizationStatus;
                createdAt: Date;
                updatedAt: Date;
                slug: string;
            };
            order: {
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
        } & {
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
        })[];
        meta: {
            total: number;
            page: number | undefined;
            limit: number | undefined;
        };
    }>;
    findOnePayment(req: any, id: string): Promise<{
        organization: {
            name: string;
            id: string;
            status: import("@prisma/client").$Enums.OrganizationStatus;
            createdAt: Date;
            updatedAt: Date;
            slug: string;
        };
        order: {
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
        refunds: {
            id: string;
            status: string;
            createdAt: Date;
            updatedAt: Date;
            currency: string;
            amount: import("@prisma/client/runtime/library").Decimal;
            paymentId: string;
            providerRefundId: string | null;
            reason: string | null;
        }[];
    } & {
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
    }>;
    findAllRefunds(req: any, query: AdminBillingQueryDto): Promise<{
        data: ({
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
        } & {
            id: string;
            status: string;
            createdAt: Date;
            updatedAt: Date;
            currency: string;
            amount: import("@prisma/client/runtime/library").Decimal;
            paymentId: string;
            providerRefundId: string | null;
            reason: string | null;
        })[];
        meta: {
            total: number;
            page: number | undefined;
            limit: number | undefined;
        };
    }>;
    findOneRefund(req: any, id: string): Promise<{
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
    } & {
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
    refundPayment(req: any, paymentId: string, dto: AdminRefundDto): Promise<{
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
