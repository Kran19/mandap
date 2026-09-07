import { WebhooksService } from '../services/webhooks.service.js';
import { Request } from 'express';
interface RequestWithRawBody extends Request {
    rawBody?: Buffer;
}
export declare class WebhooksController {
    private readonly webhooksService;
    constructor(webhooksService: WebhooksService);
    handleRazorpayWebhook(signature: string, req: RequestWithRawBody): Promise<{
        status: string;
    }>;
}
export {};
