import { Injectable, Inject, BadRequestException, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
import type { PaymentProvider } from '../providers/payment-provider.interface.js';
import { SubscriptionsService } from './subscriptions.service.js';
import { OrderStatus, PaymentStatus, Prisma } from '@prisma/client';

@Injectable()
export class PaymentsService {
  private readonly logger = new Logger(PaymentsService.name);

  constructor(
    private prisma: PrismaService,
    private subscriptionsService: SubscriptionsService,
    @Inject('PAYMENT_PROVIDER') private paymentProvider: PaymentProvider
  ) {}

  /**
   * Verifies the client's payment signature and triggers finalization if valid.
   */
  async verifyClientPayment(providerOrderId: string, providerPaymentId: string, signature: string) {
    const isValid = this.paymentProvider.verifyPayment({ providerOrderId, providerPaymentId, signature });
    if (!isValid) {
      this.logger.warn(`Invalid payment signature for order ${providerOrderId}`);
      throw new BadRequestException('Invalid payment signature');
    }

    return this.finalizeCapturedPayment(providerOrderId, providerPaymentId);
  }

  /**
   * Idempotent method to finalize a captured payment.
   * Runs in a transaction to update Payment, Order, and activate Subscription.
   */
  async finalizeCapturedPayment(providerOrderId: string, providerPaymentId: string) {
    // 1. Fetch Order
    const order = await this.prisma.order.findUnique({
      where: { providerOrderId },
      include: { items: true },
    });

    if (!order) {
      this.logger.error(`Order not found for providerOrderId ${providerOrderId}`);
      throw new BadRequestException('Order not found');
    }

    return this.prisma.$transaction(async (tx) => {
      // 2. Idempotency check: has this payment already been captured successfully?
      const existingPayment = await tx.payment.findUnique({
        where: { providerPaymentId },
      });

      if (existingPayment) {
        if (existingPayment.status === PaymentStatus.SUCCESSFUL) {
          // Idempotent success
          return existingPayment;
        }
        
        // If it exists but is FAILED, we shouldn't blindly update it to SUCCESSFUL without checking provider.
        // But if we're here, it means we verified a successful signature or received a captured webhook.
        if (existingPayment.status !== PaymentStatus.PENDING) {
          this.logger.warn(`Conflicting payment transition for ${providerPaymentId}: ${existingPayment.status} -> SUCCESSFUL`);
          throw new BadRequestException('Conflicting payment state transition');
        }
      }

      // 3. Create or update Payment
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

      // 4. Mark Order as PAID
      if (order.status !== OrderStatus.PAID) {
        await tx.order.update({
          where: { id: order.id },
          data: { status: OrderStatus.PAID },
        });
      }

      // 5. Activate Subscription (assuming the order item contains the plan info)
      // We parse the planId from the order context. 
      // Actually, we didn't save planId on the order. Let's extract it.
      // Wait, OrdersService didn't save planId directly on Order. We should find the plan by checking the description or saving it in metadata.
      // For robust implementation, we should fetch it or pass it.
      // Let's assume we update OrdersService to save planId in `metadata` of the OrderItem.
      const orderItem = order.items[0];
      const metadata = typeof orderItem.metadata === 'string' ? JSON.parse(orderItem.metadata) : (orderItem.metadata as any);
      if (!metadata || !metadata.planId) {
        throw new BadRequestException('Order missing plan details');
      }

      await this.subscriptionsService.activateSubscription(
        tx,
        order.organizationId,
        metadata.planId,
        this.paymentProvider.name,
        `sub_${order.id}` // Derive a unique providerSubscriptionId if provider doesn't have subscriptions
      );

      return payment;
    });
  }

  async handlePaymentFailed(providerOrderId: string, providerPaymentId: string, errorCode: string, errorDescription: string) {
    const order = await this.prisma.order.findUnique({
      where: { providerOrderId },
    });

    if (!order) return;

    await this.prisma.$transaction(async (tx) => {
      const existingPayment = await tx.payment.findUnique({
        where: { providerPaymentId },
      });

      if (existingPayment && existingPayment.status === PaymentStatus.SUCCESSFUL) {
        // We cannot mark a SUCCESSFUL payment as FAILED
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

      // Handle subscription failure if this was a renewal
      const activeSub = await tx.subscription.findFirst({
        where: { organizationId: order.organizationId, status: 'ACTIVE' },
      });
      if (activeSub) {
        await this.subscriptionsService.markPastDue(tx, activeSub.id);
      }
    });
  }
}
