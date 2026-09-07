export declare class AdminBillingQueryDto {
    page?: number;
    limit?: number;
    search?: string;
    get skip(): number;
}
export declare class AdminRefundDto {
    amount: number;
    reason?: string;
}
