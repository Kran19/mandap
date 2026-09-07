var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
var PaymentsService_1;
import { Injectable, Inject, BadRequestException, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
import { SubscriptionsService } from './subscriptions.service.js';
import { OrderStatus, PaymentStatus } from '@prisma/client';
let PaymentsService = PaymentsService_1 = class PaymentsService {
    prisma;
    subscriptionsService;
    paymentProvider;
    logger = new Logger(PaymentsService_1.name);
    constructor(prisma, subscriptionsService, paymentProvider) {
        this.prisma = prisma;
        this.subscriptionsService = subscriptionsService;
        this.paymentProvider = paymentProvider;
    }
    async verifyClientPayment(providerOrderId, providerPaymentId, signature) {
        const isValid = this.paymentProvider.verifyPayment({ providerOrderId, providerPaymentId, signature });
        if (!isValid) {
            this.logger.warn(`Invalid payment signature for order ${providerOrderId}`);
            throw new BadRequestException('Invalid payment signature');
        }
        return this.finalizeCapturedPayment(providerOrderId, providerPaymentId);
    }
    async finalizeCapturedPayment(providerOrderId, providerPaymentId) {
        const order = await this.prisma.order.findUnique({
            where: { providerOrderId },
            include: { items: true },
        });
        if (!order) {
            this.logger.error(`Order not found for providerOrderId ${providerOrderId}`);
            throw new BadRequestException('Order not found');
        }
        return this.prisma.$transaction(async (tx) => {
            const existingPayment = await tx.payment.findUnique({
                where: { providerPaymentId },
            });
            if (existingPayment) {
                if (existingPayment.status === PaymentStatus.SUCCESSFUL) {
                    return existingPayment;
                }
                if (existingPayment.status !== PaymentStatus.PENDING) {
                    this.logger.warn(`Conflicting payment transition for ${providerPaymentId}: ${existingPayment.status} -> SUCCESSFUL`);
                    throw new BadRequestException('Conflicting payment state transition');
                }
            }
            const payment = await tx.payment.upsert({
                where: { providerPaymentId },
                create: {
                    organizationId: order.organizationId,
                    orderId: order.id,
                    provider: this.paymentProvider.name,
                    providerPaymentId,
                    providerOrderId,
                    amount: order.totalAmount,
                    currency: order.currency,
                    status: PaymentStatus.SUCCESSFUL,
                    paidAt: new Date(),
                },
                update: {
                    status: PaymentStatus.SUCCESSFUL,
                    paidAt: new Date(),
                },
            });
            if (order.status !== OrderStatus.PAID) {
                await tx.order.update({
                    where: { id: order.id },
                    data: { status: OrderStatus.PAID },
                });
            }
            const orderItem = order.items[0];
            const metadata = typeof orderItem.metadata === 'string' ? JSON.parse(orderItem.metadata) : orderItem.metadata;
            if (!metadata || !metadata.planId) {
                throw new BadRequestException('Order missing plan details');
            }
            await this.subscriptionsService.activateSubscription(tx, order.organizationId, metadata.planId, this.paymentProvider.name, `sub_${order.id}`);
            return payment;
        });
    }
    async handlePaymentFailed(providerOrderId, providerPaymentId, errorCode, errorDescription) {
        const order = await this.prisma.order.findUnique({
            where: { providerOrderId },
        });
        if (!order)
            return;
        await this.prisma.$transaction(async (tx) => {
            const existingPayment = await tx.payment.findUnique({
                where: { providerPaymentId },
            });
            if (existingPayment && existingPayment.status === PaymentStatus.SUCCESSFUL) {
                this.logger.warn(`Cannot transition SUCCESSFUL payment ${providerPaymentId} to FAILED`);
                return;
            }
            await tx.payment.upsert({
                where: { providerPaymentId },
                create: {
                    organizationId: order.organizationId,
                    orderId: order.id,
                    provider: this.paymentProvider.name,
                    providerPaymentId,
                    providerOrderId,
                    amount: order.totalAmount,
                    currency: order.currency,
                    status: PaymentStatus.FAILED,
                    failureCode: errorCode,
                    failureMessage: errorDescription,
                },
                update: {
                    status: PaymentStatus.FAILED,
                    failureCode: errorCode,
                    failureMessage: errorDescription,
                },
            });
            await tx.order.update({
                where: { id: order.id },
                data: { status: OrderStatus.FAILED },
            });
            const activeSub = await tx.subscription.findFirst({
                where: { organizationId: order.organizationId, status: 'ACTIVE' },
            });
            if (activeSub) {
                await this.subscriptionsService.markPastDue(tx, activeSub.id);
            }
        });
    }
};
PaymentsService = PaymentsService_1 = __decorate([
    Injectable(),
    __param(2, Inject('PAYMENT_PROVIDER')),
    __metadata("design:paramtypes", [PrismaService,
        SubscriptionsService, Object])
], PaymentsService);
export { PaymentsService };
//# sourceMappingURL=payments.service.js.map