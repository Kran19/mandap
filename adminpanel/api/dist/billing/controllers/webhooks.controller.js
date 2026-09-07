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
import { Controller, Post, Headers, Req, BadRequestException } from '@nestjs/common';
import { WebhooksService } from '../services/webhooks.service.js';
let WebhooksController = class WebhooksController {
    webhooksService;
    constructor(webhooksService) {
        this.webhooksService = webhooksService;
    }
    async handleRazorpayWebhook(signature, req) {
        if (!signature) {
            throw new BadRequestException('Missing signature');
        }
        if (!req.rawBody) {
            throw new BadRequestException('Raw body not preserved');
        }
        let providerEventId;
        let eventType;
        try {
            const payload = JSON.parse(req.rawBody.toString('utf8'));
            providerEventId = payload['x-razorpay-event-id'] || payload['event_id'] || req.headers['x-razorpay-event-id'] || `req_${Date.now()}`;
            eventType = payload['event'];
            if (!eventType)
                throw new Error();
        }
        catch {
            throw new BadRequestException('Invalid payload or missing event type');
        }
        await this.webhooksService.processWebhook(signature, req.rawBody, providerEventId, eventType);
        return { status: 'ok' };
    }
};
__decorate([
    Post('razorpay'),
    __param(0, Headers('x-razorpay-signature')),
    __param(1, Req()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], WebhooksController.prototype, "handleRazorpayWebhook", null);
WebhooksController = __decorate([
    Controller('billing/webhooks'),
    __metadata("design:paramtypes", [WebhooksService])
], WebhooksController);
export { WebhooksController };
//# sourceMappingURL=webhooks.controller.js.map