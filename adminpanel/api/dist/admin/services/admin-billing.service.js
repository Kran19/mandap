var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
import { AdminAuditService } from './admin-audit.service.js';
import { RefundsService } from '../../billing/services/refunds.service.js';
let AdminBillingService = class AdminBillingService {
    prisma;
    auditService;
    refundsService;
    constructor(prisma, auditService, refundsService) {
        this.prisma = prisma;
        this.auditService = auditService;
        this.refundsService = refundsService;
    }
    async findAllSubscriptions(actorId, query) {
        const { page, limit, search, skip } = query;
        const where = {};
        if (search) {
            where.OR = [
                { providerSubscriptionId: { contains: search, mode: 'insensitive' } },
                { organization: { name: { contains: search, mode: 'insensitive' } } },
            ];
        }
        const [data, total] = await Promise.all([
            this.prisma.subscription.findMany({
                where, skip, take: limit, orderBy: { createdAt: 'desc' },
                include: { organization: true, plan: true }
            }),
            this.prisma.subscription.count({ where }),
        ]);
        return { data, meta: { total, page, limit } };
    }
    async findOneSubscription(actorId, id) {
        const sub = await this.prisma.subscription.findUnique({
            where: { id },
            include: { organization: true, plan: true, events: true }
        });
        if (!sub)
            throw new NotFoundException('Subscription not found');
        return sub;
    }
    async findAllOrders(actorId, query) {
        const { page, limit, search, skip } = query;
        const where = {};
        if (search) {
            where.OR = [
                { orderNumber: { contains: search, mode: 'insensitive' } },
                { providerOrderId: { contains: search, mode: 'insensitive' } },
            ];
        }
        const [data, total] = await Promise.all([
            this.prisma.order.findMany({
                where, skip, take: limit, orderBy: { createdAt: 'desc' },
                include: { organization: true, user: true }
            }),
            this.prisma.order.count({ where }),
        ]);
        return { data, meta: { total, page, limit } };
    }
    async findOneOrder(actorId, id) {
        const order = await this.prisma.order.findUnique({
            where: { id },
            include: { organization: true, user: true, items: true, payments: true }
        });
        if (!order)
            throw new NotFoundException('Order not found');
        return order;
    }
    async findAllPayments(actorId, query) {
        const { page, limit, search, skip } = query;
        const where = {};
        if (search) {
            where.OR = [
                { providerPaymentId: { contains: search, mode: 'insensitive' } },
            ];
        }
        const [data, total] = await Promise.all([
            this.prisma.payment.findMany({
                where, skip, take: limit, orderBy: { createdAt: 'desc' },
                include: { organization: true, order: true }
            }),
            this.prisma.payment.count({ where }),
        ]);
        return { data, meta: { total, page, limit } };
    }
    async findOnePayment(actorId, id) {
        const payment = await this.prisma.payment.findUnique({
            where: { id },
            include: { organization: true, order: true, refunds: true }
        });
        if (!payment)
            throw new NotFoundException('Payment not found');
        return payment;
    }
    async findAllRefunds(actorId, query) {
        const { page, limit, search, skip } = query;
        const where = {};
        if (search) {
            where.OR = [
                { providerRefundId: { contains: search, mode: 'insensitive' } },
            ];
        }
        const [data, total] = await Promise.all([
            this.prisma.refund.findMany({
                where, skip, take: limit, orderBy: { createdAt: 'desc' },
                include: { payment: true }
            }),
            this.prisma.refund.count({ where }),
        ]);
        return { data, meta: { total, page, limit } };
    }
    async findOneRefund(actorId, id) {
        const refund = await this.prisma.refund.findUnique({
            where: { id },
            include: { payment: true }
        });
        if (!refund)
            throw new NotFoundException('Refund not found');
        return refund;
    }
    async refundPayment(actorId, paymentId, dto) {
        const refund = await this.refundsService.createRefund(actorId, paymentId, dto.amount, dto.reason);
        await this.auditService.log(actorId, 'REFUND_CREATED', 'Refund', refund.id, null, null, refund);
        return refund;
    }
};
AdminBillingService = __decorate([
    Injectable(),
    __metadata("design:paramtypes", [PrismaService,
        AdminAuditService,
        RefundsService])
], AdminBillingService);
export { AdminBillingService };
//# sourceMappingURL=admin-billing.service.js.map