import { Injectable, Inject, Logger, BadRequestException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
import type { PaymentProvider } from '../providers/payment-provider.interface.js';
import { PaymentsService } from './payments.service.js';
import { SubscriptionsService } from './subscriptions.service.js';
import * as crypto from 'crypto';

@Injectable()
export class WebhooksService {
  private readonly logger = new Logger(WebhooksService.name);

  constructor(
    private prisma: PrismaService,
    private paymentsService: PaymentsService,
    private subscriptionsService: SubscriptionsService,
    @Inject('PAYMENT_PROVIDER') private paymentProvider: PaymentProvider
  ) {}

  async processWebhook(
    signature: string,
    rawBody: Buffer,
    providerEventId: string,
    eventType: string
  ) {
    // 1. Verify Signature
    const isValid = this.paymentProvider.verifyWebhookSignature(rawBody.toString('utf8'), signature);
    if (!isValid) {
      this.logger.warn(`Invalid webhook signature from ${this.paymentProvider.name}`);
      throw new BadRequestException('Invalid webhook signature');
    }

    const payloadString = rawBody.toString('utf8');
    const payloadHash = crypto.createHash('sha256').update(payloadString).digest('hex');
    let payloadJson: any;
    try {
      payloadJson = JSON.parse(payloadString);
    } catch {
      throw new BadRequestException('Invalid JSON payload');
    }

    // 2. Idempotency Check
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
        return; // Idempotent success
      }

      if (existingEvent.status === 'PENDING') {
        this.logger.warn(`Webhook event ${providerEventId} is currently being processed. Ignoring duplicate delivery.`);
        // Returning 409 to trigger provider's retry if it's a genuine race condition where the first fails.
        throw new ConflictException('Webhook currently processing');
      }
      
      // If FAILED, we will retry processing
    } else {
      // Create new event
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

    // 3. Process Event
    try {
      await this.prisma.webhookEvent.update({
        where: { provider_eventId: { provider: this.paymentProvider.name, eventId: providerEventId } },
        data: {
          attempts: { increment: 1 },
          lastAttemptAt: new Date(),
        },
      });

      await this.handleProviderEvent(eventType, payloadJson);

      // 4. Mark PROCESSED
      await this.prisma.webhookEvent.update({
        where: { provider_eventId: { provider: this.paymentProvider.name, eventId: providerEventId } },
        data: {
          status: 'PROCESSED',
          processedAt: new Date(),
          lastError: null,
        },
      });
    } catch (error: any) {
      this.logger.error(`Failed to process webhook ${providerEventId}: ${error.message}`);
      // Mark FAILED
      await this.prisma.webhookEvent.update({
        where: { provider_eventId: { provider: this.paymentProvider.name, eventId: providerEventId } },
        data: {
          status: 'FAILED',
          lastError: error.message || 'Unknown error',
        },
      });
      // Throw to ensure Razorpay considers it a failure and retries
      throw new BadRequestException('Failed to process webhook');
    }
  }

  private async handleProviderEvent(eventType: string, payload: any) {
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
        if (!paymentEntity) throw new BadRequestException('Malformed payment.failed payload');
        
        await this.paymentsService.handlePaymentFailed(
          paymentEntity.order_id,
          paymentEntity.id,
          paymentEntity.error_code,
          paymentEntity.error_description
        );
        break;
      }

      case 'subscription.authenticated': {
        const subscriptionEntity = payload.payload?.subscription?.entity;
        if (!subscriptionEntity) throw new BadRequestException('Malformed subscription.authenticated payload');

        // This establishes the trial when mandate is authorized
        await this.prisma.$transaction(async (tx) => {
          await this.subscriptionsService.establishTrial(tx, subscriptionEntity.id);
        });
        break;
      }

      case 'subscription.activated': {
        const subscriptionEntity = payload.payload?.subscription?.entity;
        if (!subscriptionEntity) throw new BadRequestException('Malformed subscription.activated payload');

        // This activates the subscription when the trial converts to active
        // Or if it was a direct non-trial subscription
        // Wait, for TRIALING to ACTIVE conversion, the charge succeeds and triggers payment.captured, 
        // which triggers finalizeCapturedPayment and calls activateSubscription.
        // So we can optionally just log it, or rely on payment.captured.
        this.logger.log(`Subscription ${subscriptionEntity.id} activated`);
        break;
      }

      // Ignore unsupported events safely
      default:
        this.logger.log(`Ignoring unsupported webhook event: ${eventType}`);
        break;
    }
  }
}
