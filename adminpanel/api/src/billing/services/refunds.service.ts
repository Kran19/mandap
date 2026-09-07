import { Injectable, Inject, BadRequestException, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
import type { PaymentProvider } from '../providers/payment-provider.interface.js';
import { PaymentStatus } from '@prisma/client';

@Injectable()
export class RefundsService {
  constructor(
    private prisma: PrismaService,
    @Inject('PAYMENT_PROVIDER') private paymentProvider: PaymentProvider
  ) {}

  async createRefund(actorId: string, paymentId: string, amount: number, reason?: string) {
    const payment = await this.prisma.payment.findUnique({
      where: { id: paymentId },
      include: { refunds: true },
    });

    if (!payment) throw new NotFoundException('Payment not found');
    if (payment.status !== PaymentStatus.SUCCESSFUL && payment.status !== PaymentStatus.PARTIALLY_REFUNDED) {
      throw new BadRequestException('Payment is not eligible for refund');
    }

    // Convert decimal to number for calculation
    const paymentAmount = parseFloat(payment.amount.toString());
    const existingRefundsAmount = payment.refunds
      .filter((r) => r.status === 'PROCESSED' || r.status === 'PENDING')
      .reduce((sum, r) => sum + parseFloat(r.amount.toString()), 0);

    const maxRefundable = paymentAmount - existingRefundsAmount;
    if (amount > maxRefundable) {
      throw new BadRequestException(`Cannot refund more than remaining captured amount. Max refundable: ${maxRefundable}`);
    }

    const amountInBaseUnit = Math.round(amount * 100);

    // Call Provider
    let providerRefund;
    try {
      providerRefund = await this.paymentProvider.refundPayment({
        providerPaymentId: payment.providerPaymentId as string,
        amount: amountInBaseUnit,
        currency: payment.currency,
        receiptId: `ref_${Date.now()}`,
      });
    } catch (e: any) {
      throw new ConflictException(`Provider refund failed: ${e.message}`);
    }

    // Record Refund
    const refund = await this.prisma.refund.create({
      data: {
        paymentId: payment.id,
        providerRefundId: providerRefund.id,
        amount,
        currency: payment.currency,
        status: 'PROCESSED',
        reason,
      },
    });

    // Update payment status
    const newStatus = existingRefundsAmount + amount >= paymentAmount ? PaymentStatus.REFUNDED : PaymentStatus.PARTIALLY_REFUNDED;
    await this.prisma.payment.update({
      where: { id: payment.id },
      data: { status: newStatus },
    });

    return refund;
  }
}
