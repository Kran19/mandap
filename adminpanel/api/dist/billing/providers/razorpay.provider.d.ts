import { ConfigService } from '@nestjs/config';
import { CreateOrderParams, PaymentProvider, ProviderOrder, ProviderPayment, ProviderRefund, RefundParams, VerifyPaymentParams } from './payment-provider.interface.js';
export declare class RazorpayProvider implements PaymentProvider {
    private configService;
    readonly name = "RAZORPAY";
    private readonly logger;
    private instance;
    constructor(configService: ConfigService);
    private executeWithTimeout;
    createOrder(params: CreateOrderParams): Promise<ProviderOrder>;
    verifyPayment(params: VerifyPaymentParams): boolean;
    verifyWebhookSignature(body: string, signature: string): boolean;
    fetchPayment(paymentId: string): Promise<ProviderPayment>;
    refundPayment(params: RefundParams): Promise<ProviderRefund>;
    createSubscription(params: any): Promise<any>;
}
