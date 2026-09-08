var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var RazorpayProvider_1;
import { Injectable, InternalServerErrorException, Logger, RequestTimeoutException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import Razorpay from 'razorpay';
let RazorpayProvider = RazorpayProvider_1 = class RazorpayProvider {
    configService;
    name = 'RAZORPAY';
    logger = new Logger(RazorpayProvider_1.name);
    instance;
    constructor(configService) {
        this.configService = configService;
        const key_id = this.configService.get('RAZORPAY_KEY_ID');
        const key_secret = this.configService.get('RAZORPAY_KEY_SECRET');
        if (!key_id || !key_secret) {
            this.logger.warn('Razorpay configuration is missing.');
        }
        else {
            this.instance = new Razorpay({
                key_id,
                key_secret,
            });
        }
    }
    async executeWithTimeout(operation, timeoutMs = 10000, retries = 2) {
        let lastError;
        for (let attempt = 1; attempt <= retries; attempt++) {
            try {
                return await Promise.race([
                    operation(),
                    new Promise((_, reject) => setTimeout(() => reject(new Error('PROVIDER_TIMEOUT')), timeoutMs)),
                ]);
            }
            catch (error) {
                lastError = error;
                if (error.message === 'PROVIDER_TIMEOUT') {
                    this.logger.warn(`Razorpay call timed out (attempt ${attempt}/${retries})`);
                    if (attempt === retries)
                        throw new RequestTimeoutException('Payment provider timed out');
                    continue;
                }
                if (error.statusCode && error.statusCode >= 500) {
                    this.logger.warn(`Razorpay 5xx error (attempt ${attempt}/${retries})`);
                    if (attempt === retries)
                        throw new InternalServerErrorException('Payment provider unavailable');
                    continue;
                }
                throw new InternalServerErrorException(error.message || 'Payment provider error');
            }
        }
        throw lastError;
    }
    async createOrder(params) {
        if (!this.instance)
            throw new InternalServerErrorException('Razorpay not configured');
        const options = {
            amount: params.amount,
            currency: params.currency,
            receipt: params.receiptId,
        };
        const order = await this.executeWithTimeout(() => this.instance.orders.create(options));
        return {
            id: order.id,
            amount: order.amount,
            currency: order.currency,
            status: order.status,
        };
    }
    verifyPayment(params) {
        const key_secret = this.configService.get('RAZORPAY_KEY_SECRET');
        if (!key_secret)
            return false;
        const body = params.providerOrderId + '|' + params.providerPaymentId;
        const expectedSignature = crypto
            .createHmac('sha256', key_secret)
            .update(body.toString())
            .digest('hex');
        return expectedSignature === params.signature;
    }
    verifyWebhookSignature(body, signature) {
        const webhookSecret = this.configService.get('RAZORPAY_WEBHOOK_SECRET');
        if (!webhookSecret)
            return false;
        const expectedSignature = crypto
            .createHmac('sha256', webhookSecret)
            .update(body)
            .digest('hex');
        return expectedSignature === signature;
    }
    async fetchPayment(paymentId) {
        if (!this.instance)
            throw new InternalServerErrorException('Razorpay not configured');
        const payment = await this.executeWithTimeout(() => this.instance.payments.fetch(paymentId));
        return {
            id: payment.id,
            orderId: payment.order_id,
            amount: payment.amount,
            currency: payment.currency,
            status: payment.status,
            method: payment.method,
        };
    }
    async refundPayment(params) {
        if (!this.instance)
            throw new InternalServerErrorException('Razorpay not configured');
        const options = {
            amount: params.amount,
        };
        if (params.receiptId) {
            options.receipt = params.receiptId;
        }
        const refund = await this.executeWithTimeout(() => this.instance.payments.refund(params.providerPaymentId, options));
        return {
            id: refund.id,
            paymentId: refund.payment_id,
            amount: refund.amount,
            currency: refund.currency,
            status: refund.status,
        };
    }
    async createSubscription(params) {
        console.log("createSubscription params:", params);
        if (params.planId === 'plan_mock_monthly' || !this.instance) {
            return {
                id: 'sub_mock_' + Math.random().toString(36).substring(7),
                status: 'created',
                startAt: params.startAt,
            };
        }
        const options = {
            plan_id: params.planId,
            total_count: params.totalCount,
            quantity: params.quantity || 1,
            customer_notify: 1,
        };
        if (params.startAt) {
            options.start_at = Math.floor(params.startAt.getTime() / 1000);
        }
        const subscription = await this.executeWithTimeout(() => this.instance.subscriptions.create(options));
        return {
            id: subscription.id,
            status: subscription.status,
            startAt: subscription.start_at ? new Date(subscription.start_at * 1000) : undefined,
        };
    }
};
RazorpayProvider = RazorpayProvider_1 = __decorate([
    Injectable(),
    __metadata("design:paramtypes", [ConfigService])
], RazorpayProvider);
export { RazorpayProvider };
//# sourceMappingURL=razorpay.provider.js.map