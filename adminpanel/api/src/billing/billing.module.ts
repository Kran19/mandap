import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from '../prisma.module.js';
import { PlansService } from './services/plans.service.js';
import { RazorpayProvider } from './providers/razorpay.provider.js';

import { SubscriptionsService } from './services/subscriptions.service.js';
import { OrdersService } from './services/orders.service.js';
import { PaymentsService } from './services/payments.service.js';
import { RefundsService } from './services/refunds.service.js';
import { WebhooksService } from './services/webhooks.service.js';
import { EntitlementService } from './services/entitlement.service.js';
import { CheckoutController } from './controllers/checkout.controller.js';
import { WebhooksController } from './controllers/webhooks.controller.js';
import { EntitlementController } from './controllers/entitlement.controller.js';
import { TrialEligibilityService } from './services/trial-eligibility.service.js';

import { TrialController } from './controllers/trial.controller.js';
import { PlansController } from './controllers/plans.controller.js';

@Module({
  imports: [ConfigModule, PrismaModule],
  controllers: [CheckoutController, WebhooksController, TrialController, PlansController, EntitlementController],
  providers: [
    PlansService,
    SubscriptionsService,
    OrdersService,
    PaymentsService,
    RefundsService,
    WebhooksService,
    EntitlementService,
    TrialEligibilityService,
    RazorpayProvider,
    {
      provide: 'PAYMENT_PROVIDER',
      useClass: RazorpayProvider,
    },
  ],
  exports: [PlansService, SubscriptionsService, OrdersService, PaymentsService, RefundsService, WebhooksService, EntitlementService, TrialEligibilityService, 'PAYMENT_PROVIDER'],
})
export class BillingModule {}
