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
var WebhooksService_1;
import { Injectable, Inject, Logger, BadRequestException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
import { PaymentsService } from './payments.service.js';
import { SubscriptionsService } from './subscriptions.service.js';
import * as crypto from 'crypto';
let WebhooksService = WebhooksService_1 = class WebhooksService {
    prisma;
    paymentsService;
    subscriptionsService;
    paymentProvider;
    logger = new Logger(WebhooksService_1.name);
    constructor(prisma, paymentsService, subscriptionsService, paymentProvider) {
        this.prisma = prisma;
        this.paymentsService = paymentsService;
        this.subscriptionsService = subscriptionsService;
        this.paymentProvider = paymentProvider;
    }
    async processWebhook(signature, rawBody, providerEventId, eventType) {
        const isValid = this.paymentProvider.verifyWebhookSignature(rawBody.toString('utf8'), signature);
        if (!isValid) {
            this.logger.warn(`Invalid webhook signature from ${this.paymentProvider.name}`);
            throw new BadRequestException('Invalid webhook signature');
        }
        const payloadString = rawBody.toString('utf8');
        const payloadHash = crypto.createHash('sha256').update(payloadString).digest('hex');
        let payloadJson;
        try {
            payloadJson = JSON.parse(payloadString);
        }
        catch {
            throw new BadRequestException('Invalid JSON payload');
        }
        const existingEvent = await this.prisma.webhookEvent.findUnique({
            where: {
                provider_eventId: {
                    provider: this.paymentProvider.name,
                    eventId: providerEventId,
                },
            },
        });
        if (existingEvent) {
            if (existingEvent.payloadHash !== payloadHash) {
                this.logger.error(`Webhook payload mismatch for event ${providerEventId}. Possible tampering or collision.`);
                throw new ConflictException('Conflicting webhook payload');
            }
            if (existingEvent.status === 'PROCESSED') {
                this.logger.log(`Webhook event ${providerEventId} already processed.`);
                return;
            }
            if (existingEvent.status === 'PENDING') {
                this.logger.warn(`Webhook event ${providerEventId} is currently being processed. Ignoring duplicate delivery.`);
                throw new ConflictException('Webhook currently processing');
            }
        }
        else {
            await this.prisma.webhookEvent.create({
                data: {
                    provider: this.paymentProvider.name,
                    eventId: providerEventId,
                    eventType,
                    payloadHash,
                    payload: payloadJson,
                    status: 'PENDING',
                },
            });
        }
        try {
            await this.prisma.webhookEvent.update({
                where: { provider_eventId: { provider: this.paymentProvider.name, eventId: providerEventId } },
                data: {
                    attempts: { increment: 1 },
                    lastAttemptAt: new Date(),
                },
            });
            await this.handleProviderEvent(eventType, payloadJson);
            await this.prisma.webhookEvent.update({
                where: { provider_eventId: { provider: this.paymentProvider.name, eventId: providerEventId } },
                data: {
                    status: 'PROCESSED',
                    processedAt: new Date(),
                    lastError: null,
                },
            });
        }
        catch (error) {
            this.logger.error(`Failed to process webhook ${providerEventId}: ${error.message}`);
            await this.prisma.webhookEvent.update({
                where: { provider_eventId: { provider: this.paymentProvider.name, eventId: providerEventId } },
                data: {
                    status: 'FAILED',
                    lastError: error.message || 'Unknown error',
                },
            });
            throw new BadRequestException('Failed to process webhook');
        }
    }
    async handleProviderEvent(eventType, payload) {
        switch (eventType) {
            case 'payment.captured': {
                const providerOrderId = payload.payload?.payment?.entity?.order_id;
                const providerPaymentId = payload.payload?.payment?.entity?.id;
                if (providerOrderId && providerPaymentId) {
                    await this.paymentsService.finalizeCapturedPayment(providerOrderId, providerPaymentId);
                }
                break;
            }
            case 'payment.failed': {
                const paymentEntity = payload.payload?.payment?.entity;
                if (!paymentEntity)
                    throw new BadRequestException('Malformed payment.failed payload');
                await this.paymentsService.handlePaymentFailed(paymentEntity.order_id, paymentEntity.id, paymentEntity.error_code, paymentEntity.error_description);
                break;
            }
            case 'subscription.authenticated': {
                const subscriptionEntity = payload.payload?.subscription?.entity;
                if (!subscriptionEntity)
                    throw new BadRequestException('Malformed subscription.authenticated payload');
                await this.prisma.$transaction(async (tx) => {
                    await this.subscriptionsService.establishTrial(tx, subscriptionEntity.id);
                });
                break;
            }
            case 'subscription.activated': {
                const subscriptionEntity = payload.payload?.subscription?.entity;
                if (!subscriptionEntity)
                    throw new BadRequestException('Malformed subscription.activated payload');
                this.logger.log(`Subscription ${subscriptionEntity.id} activated`);
                break;
            }
            default:
                this.logger.log(`Ignoring unsupported webhook event: ${eventType}`);
                break;
        }
    }
};
WebhooksService = WebhooksService_1 = __decorate([
    Injectable(),
    __param(3, Inject('PAYMENT_PROVIDER')),
    __metadata("design:paramtypes", [PrismaService,
        PaymentsService,
        SubscriptionsService, Object])
], WebhooksService);
export { WebhooksService };
//# sourceMappingURL=webhooks.service.js.map