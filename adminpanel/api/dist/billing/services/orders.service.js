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
import { Injectable, Inject, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
import { PlansService } from './plans.service.js';
import { OrderStatus } from '@prisma/client';
import { randomBytes } from 'crypto';
let OrdersService = class OrdersService {
    prisma;
    plansService;
    paymentProvider;
    constructor(prisma, plansService, paymentProvider) {
        this.prisma = prisma;
        this.plansService = plansService;
        this.paymentProvider = paymentProvider;
    }
    async createCheckoutOrder(organizationId, userId, planSlug, interval) {
        const plan = await this.plansService.getPlanBySlug(planSlug);
        const amountDecimal = interval === 'monthly' ? plan.monthlyPrice : plan.yearlyPrice;
        if (!amountDecimal) {
            throw new BadRequestException(`Plan ${planSlug} does not support ${interval} billing`);
        }
        const amountFloat = parseFloat(amountDecimal.toString());
        const amountInBaseUnit = Math.round(amountFloat * 100);
        const orderNumber = `ORD-${Date.now()}-${randomBytes(4).toString('hex').toUpperCase()}`;
        const order = await this.prisma.order.create({
            data: {
                organizationId,
                userId,
                orderNumber,
                status: OrderStatus.PENDING,
                currency: plan.currency,
                subtotal: amountDecimal,
                totalAmount: amountDecimal,
                items: {
                    create: [
                        {
                            description: `Subscription to ${plan.name} (${interval})`,
                            quantity: 1,
                            unitAmount: amountDecimal,
                            totalAmount: amountDecimal,
                            metadata: { planId: plan.id, interval },
                        },
                    ],
                },
            },
            include: { items: true },
        });
        let providerOrder;
        try {
            providerOrder = await this.paymentProvider.createOrder({
                amount: amountInBaseUnit,
                currency: plan.currency,
                receiptId: order.id,
            });
        }
        catch (e) {
            await this.prisma.order.update({
                where: { id: order.id },
                data: { status: OrderStatus.FAILED },
            });
            throw e;
        }
        const updatedOrder = await this.prisma.order.update({
            where: { id: order.id },
            data: {
                provider: this.paymentProvider.name,
                providerOrderId: providerOrder.id,
            },
            include: { items: true },
        });
        return {
            order: updatedOrder,
            checkout: {
                providerOrderId: providerOrder.id,
                amount: providerOrder.amount,
                currency: providerOrder.currency,
                keyId: process.env.RAZORPAY_KEY_ID,
            },
        };
    }
};
OrdersService = __decorate([
    Injectable(),
    __param(2, Inject('PAYMENT_PROVIDER')),
    __metadata("design:paramtypes", [PrismaService,
        PlansService, Object])
], OrdersService);
export { OrdersService };
//# sourceMappingURL=orders.service.js.map