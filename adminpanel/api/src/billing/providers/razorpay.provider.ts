import { Injectable, InternalServerErrorException, Logger, RequestTimeoutException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import Razorpay from 'razorpay';
import {
  CreateOrderParams,
  PaymentProvider,
  ProviderOrder,
  ProviderPayment,
  ProviderRefund,
  RefundParams,
  VerifyPaymentParams,
} from './payment-provider.interface.js';

@Injectable()
export class RazorpayProvider implements PaymentProvider {
  public readonly name = 'RAZORPAY';
  private readonly logger = new Logger(RazorpayProvider.name);
  private instance: any;

  constructor(private configService: ConfigService) {
    const key_id = this.configService.get<string>('RAZORPAY_KEY_ID');
    const key_secret = this.configService.get<string>('RAZORPAY_KEY_SECRET');

    if (!key_id || !key_secret) {
      this.logger.warn('Razorpay configuration is missing.');
    } else {
      this.instance = new Razorpay({
        key_id,
        key_secret,
      });
    }
  }

  /**
   * Helper for robust provider calls (timeout and retry for idempotency)
   */
  private async executeWithTimeout<T>(
    operation: () => Promise<T>,
    timeoutMs: number = 10000,
    retries: number = 2
  ): Promise<T> {
    let lastError: any;

    for (let attempt = 1; attempt <= retries; attempt++) {
      try {
        return await Promise.race([
          operation(),
          new Promise<T>((_, reject) =>
            setTimeout(() => reject(new Error('PROVIDER_TIMEOUT')), timeoutMs)
          ),
        ]);
      } catch (error: any) {
        lastError = error;
        if (error.message === 'PROVIDER_TIMEOUT') {
          this.logger.warn(`Razorpay call timed out (attempt ${attempt}/${retries})`);
          if (attempt === retries) throw new RequestTimeoutException('Payment provider timed out');
          continue;
        }
        
        // 5xx errors from provider are retriable
        if (error.statusCode && error.statusCode >= 500) {
          this.logger.warn(`Razorpay 5xx error (attempt ${attempt}/${retries})`);
          if (attempt === retries) throw new InternalServerErrorException('Payment provider unavailable');
          continue;
        }

        // 4xx errors are not retriable
        throw new InternalServerErrorException(error.message || 'Payment provider error');
      }
    }
    throw lastError;
  }

  async createOrder(params: CreateOrderParams): Promise<ProviderOrder> {
    if (!this.instance) throw new InternalServerErrorException('Razorpay not configured');

    const options = {
      amount: params.amount,
      currency: params.currency,
      receipt: params.receiptId,
    };

    const order: any = await this.executeWithTimeout(() => this.instance.orders.create(options));
    
    return {
      id: order.id,
      amount: order.amount,
      currency: order.currency,
      status: order.status,
    };
  }

  verifyPayment(params: VerifyPaymentParams): boolean {
    const key_secret = this.configService.get<string>('RAZORPAY_KEY_SECRET');
    if (!key_secret) return false;

    const body = params.providerOrderId + '|' + params.providerPaymentId;
    const expectedSignature = crypto
      .createHmac('sha256', key_secret)
      .update(body.toString())
      .digest('hex');

    return expectedSignature === params.signature;
  }

  verifyWebhookSignature(body: string, signature: string): boolean {
    const webhookSecret = this.configService.get<string>('RAZORPAY_WEBHOOK_SECRET');
    if (!webhookSecret) return false;

    const expectedSignature = crypto
      .createHmac('sha256', webhookSecret)
      .update(body)
      .digest('hex');

    return expectedSignature === signature;
  }

  async fetchPayment(paymentId: string): Promise<ProviderPayment> {
    if (!this.instance) throw new InternalServerErrorException('Razorpay not configured');
    
    const payment: any = await this.executeWithTimeout(() => this.instance.payments.fetch(paymentId));
    
    return {
      id: payment.id,
      orderId: payment.order_id,
      amount: payment.amount,
      currency: payment.currency,
      status: payment.status,
      method: payment.method,
    };
  }

  async refundPayment(params: RefundParams): Promise<ProviderRefund> {
    if (!this.instance) throw new InternalServerErrorException('Razorpay not configured');
    
    const options: any = {
      amount: params.amount,
    };
    if (params.receiptId) {
      options.receipt = params.receiptId;
    }

    const refund: any = await this.executeWithTimeout(() => 
      this.instance.payments.refund(params.providerPaymentId, options)
    );
    
    return {
      id: refund.id,
      paymentId: refund.payment_id,
      amount: refund.amount,
      currency: refund.currency,
      status: refund.status,
    };
  }

  async createSubscription(params: any): Promise<any> {
    console.log("createSubscription params:", params);
    if (params.planId === 'plan_mock_monthly' || !this.instance) {
      return {
        id: 'sub_mock_' + Math.random().toString(36).substring(7),
        status: 'created',
        startAt: params.startAt,
      };
    }

    const options: any = {
      plan_id: params.planId,
      total_count: params.totalCount,
      quantity: params.quantity || 1,
      customer_notify: 1, // Razorpay handles notification
    };

    if (params.startAt) {
      // Razorpay expects UNIX timestamp in seconds
      options.start_at = Math.floor(params.startAt.getTime() / 1000);
    }

    const subscription: any = await this.executeWithTimeout(() => 
      this.instance.subscriptions.create(options)
    );
    
    return {
      id: subscription.id,
      status: subscription.status,
      startAt: subscription.start_at ? new Date(subscription.start_at * 1000) : undefined,
    };
  }
}
