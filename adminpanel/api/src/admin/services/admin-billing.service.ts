import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
import { AdminAuditService } from './admin-audit.service.js';
import { AdminBillingQueryDto, AdminRefundDto } from '../dto/admin-billing.dto.js';
import { RefundsService } from '../../billing/services/refunds.service.js';

@Injectable()
export class AdminBillingService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditService: AdminAuditService,
    private readonly refundsService: RefundsService
  ) {}

  async findAllSubscriptions(actorId: string, query: AdminBillingQueryDto) {
    const { page, limit, search, skip } = query;
    const where: any = {};
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

  async findOneSubscription(actorId: string, id: string) {
    const sub = await this.prisma.subscription.findUnique({
      where: { id },
      include: { organization: true, plan: true, events: true }
    });
    if (!sub) throw new NotFoundException('Subscription not found');
    return sub;
  }

  async findAllOrders(actorId: string, query: AdminBillingQueryDto) {
    const { page, limit, search, skip } = query;
    const where: any = {};
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

  async findOneOrder(actorId: string, id: string) {
    const order = await this.prisma.order.findUnique({
      where: { id },
      include: { organization: true, user: true, items: true, payments: true }
    });
    if (!order) throw new NotFoundException('Order not found');
    return order;
  }

  async findAllPayments(actorId: string, query: AdminBillingQueryDto) {
    const { page, limit, search, skip } = query;
    const where: any = {};
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

  async findOnePayment(actorId: string, id: string) {
    const payment = await this.prisma.payment.findUnique({
      where: { id },
      include: { organization: true, order: true, refunds: true }
    });
    if (!payment) throw new NotFoundException('Payment not found');
    return payment;
  }

  async findAllRefunds(actorId: string, query: AdminBillingQueryDto) {
    const { page, limit, search, skip } = query;
    const where: any = {};
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

  async findOneRefund(actorId: string, id: string) {
    const refund = await this.prisma.refund.findUnique({
      where: { id },
      include: { payment: true }
    });
    if (!refund) throw new NotFoundException('Refund not found');
    return refund;
  }

  async refundPayment(actorId: string, paymentId: string, dto: AdminRefundDto) {
    const refund = await this.refundsService.createRefund(actorId, paymentId, dto.amount, dto.reason);
    
    // We do NOT use the tx from Prisma for this audit log since refundsService does not expose it,
    // but we log it as an admin operation.
    await this.auditService.log(
      actorId,
      'REFUND_CREATED',
      'Refund',
      refund.id,
      null,
      null,
      refund
    );

    return refund;
  }
}
