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
import { Injectable, Inject, BadRequestException, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
import { PaymentStatus } from '@prisma/client';
let RefundsService = class RefundsService {
    prisma;
    paymentProvider;
    constructor(prisma, paymentProvider) {
        this.prisma = prisma;
        this.paymentProvider = paymentProvider;
    }
    async createRefund(actorId, paymentId, amount, reason) {
        const payment = await this.prisma.payment.findUnique({
            where: { id: paymentId },
            include: { refunds: true },
        });
        if (!payment)
            throw new NotFoundException('Payment not found');
        if (payment.status !== PaymentStatus.SUCCESSFUL && payment.status !== PaymentStatus.PARTIALLY_REFUNDED) {
            throw new BadRequestException('Payment is not eligible for refund');
        }
        const paymentAmount = parseFloat(payment.amount.toString());
        const existingRefundsAmount = payment.refunds
            .filter((r) => r.status === 'PROCESSED' || r.status === 'PENDING')
            .reduce((sum, r) => sum + parseFloat(r.amount.toString()), 0);
        const maxRefundable = paymentAmount - existingRefundsAmount;
        if (amount > maxRefundable) {
            throw new BadRequestException(`Cannot refund more than remaining captured amount. Max refundable: ${maxRefundable}`);
        }
        const amountInBaseUnit = Math.round(amount * 100);
        let providerRefund;
        try {
            providerRefund = await this.paymentProvider.refundPayment({
                providerPaymentId: payment.providerPaymentId,
                amount: amountInBaseUnit,
                currency: payment.currency,
                receiptId: `ref_${Date.now()}`,
            });
        }
        catch (e) {
            throw new ConflictException(`Provider refund failed: ${e.message}`);
        }
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
        const newStatus = existingRefundsAmount + amount >= paymentAmount ? PaymentStatus.REFUNDED : PaymentStatus.PARTIALLY_REFUNDED;
        await this.prisma.payment.update({
            where: { id: payment.id },
            data: { status: newStatus },
        });
        return refund;
    }
};
RefundsService = __decorate([
    Injectable(),
    __param(1, Inject('PAYMENT_PROVIDER')),
    __metadata("design:paramtypes", [PrismaService, Object])
], RefundsService);
export { RefundsService };
//# sourceMappingURL=refunds.service.js.map