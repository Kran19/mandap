import { Injectable, Inject, BadRequestException, InternalServerErrorException } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
import { PlansService } from './plans.service.js';
import type { PaymentProvider } from '../providers/payment-provider.interface.js';
import { OrderStatus } from '@prisma/client';
import { randomBytes } from 'crypto';

@Injectable()
export class OrdersService {
  constructor(
    private prisma: PrismaService,
    private plansService: PlansService,
    @Inject('PAYMENT_PROVIDER') private paymentProvider: PaymentProvider
  ) {}

  async createCheckoutOrder(organizationId: string, userId: string, planSlug: string, interval: 'monthly' | 'yearly') {
    const plan = await this.plansService.getPlanBySlug(planSlug);

    const amountDecimal = interval === 'monthly' ? plan.monthlyPrice : plan.yearlyPrice;
    if (!amountDecimal) {
      throw new BadRequestException(`Plan ${planSlug} does not support ${interval} billing`);
    }

    // Convert decimal to provider base unit (e.g. paise for INR). Assumes standard 2 decimal places.
    // e.g. 100.00 -> 10000
    const amountFloat = parseFloat(amountDecimal.toString());
    const amountInBaseUnit = Math.round(amountFloat * 100);

    const orderNumber = `ORD-${Date.now()}-${randomBytes(4).toString('hex').toUpperCase()}`;

    // 1. Create MANDAP order
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

    // 2. Create provider order
    let providerOrder;
    try {
      providerOrder = await this.paymentProvider.createOrder({
        amount: amountInBaseUnit,
        currency: plan.currency,
        receiptId: order.id,
      });
    } catch (e: any) {
      // If provider fails, mark order as FAILED
      await this.prisma.order.update({
        where: { id: order.id },
        data: { status: OrderStatus.FAILED },
      });
      throw e;
    }

    // 3. Persist providerOrderId safely
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
        keyId: process.env.RAZORPAY_KEY_ID, // Safe public metadata for client SDK
      },
    };
  }
}
