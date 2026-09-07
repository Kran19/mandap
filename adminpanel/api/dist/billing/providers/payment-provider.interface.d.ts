export interface CreateOrderParams {
    amount: number;
    currency: string;
    receiptId: string;
}
export interface VerifyPaymentParams {
    providerOrderId: string;
    providerPaymentId: string;
    signature: string;
}
export interface RefundParams {
    providerPaymentId: string;
    amount: number;
    currency: string;
    receiptId?: string;
}
export interface ProviderOrder {
    id: string;
    amount: number;
    currency: string;
    status: string;
}
export interface ProviderPayment {
    id: string;
    orderId: string;
    amount: number;
    currency: string;
    status: string;
    method?: string;
}
export interface ProviderRefund {
    id: string;
    paymentId: string;
    amount: number;
    currency: string;
    status: string;
}
export interface CreateSubscriptionParams {
    planId: string;
    totalCount: number;
    startAt?: Date;
    quantity?: number;
}
export interface ProviderSubscription {
    id: string;
    status: string;
    startAt?: Date;
}
export interface PaymentProvider {
    name: string;
    createOrder(params: CreateOrderParams): Promise<ProviderOrder>;
    verifyPayment(params: VerifyPaymentParams): boolean;
    verifyWebhookSignature(body: string, signature: string): boolean;
    fetchPayment(paymentId: string): Promise<ProviderPayment>;
    refundPayment(params: RefundParams): Promise<ProviderRefund>;
    createSubscription?(params: CreateSubscriptionParams): Promise<ProviderSubscription>;
    fetchSubscription?(subscriptionId: string): Promise<ProviderSubscription>;
}
