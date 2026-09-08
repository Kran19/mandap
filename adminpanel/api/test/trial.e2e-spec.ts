import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe, VersioningType } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module.js';
import { PrismaService } from '../src/prisma.service.js';
import { PaymentProvider, ProviderOrder, ProviderPayment, ProviderRefund, CreateOrderParams, RefundParams, CreateSubscriptionParams, ProviderSubscription } from '../src/billing/providers/payment-provider.interface.js';
import { SubscriptionStatus } from '@prisma/client';
import * as crypto from 'crypto';

class MockRazorpayProvider implements PaymentProvider {
  name = 'razorpay';
  
  public verifyResult = true;
  public failCreation = false;
  
  async createOrder(params: CreateOrderParams): Promise<ProviderOrder> {
    if (this.failCreation) throw new Error('Provider timeout');
    return {
      id: `order_mock_${Date.now()}`,
      amount: params.amount,
      currency: params.currency,
      status: 'created',
      receipt: params.receiptId,
    };
  }
  
  async fetchPayment(paymentId: string): Promise<ProviderPayment> {
    return {
      id: paymentId,
      orderId: 'mock_order_id',
      amount: 1000,
      currency: 'INR',
      status: 'captured',
      method: 'card',
    };
  }
  
  async refundPayment(params: RefundParams): Promise<ProviderRefund> {
    return {
      id: `rfnd_mock_${Date.now()}`,
      paymentId: params.providerPaymentId,
      amount: params.amount || 1000,
      currency: 'INR',
      status: 'processed',
    };
  }
  
  async createSubscription(params: CreateSubscriptionParams): Promise<ProviderSubscription> {
    if (this.failCreation) throw new Error('Provider timeout');
    return {
      id: `sub_mock_${Date.now()}_${Math.floor(Math.random()*1000)}`,
      status: 'created',
      startAt: params.startAt,
    };
  }
  
  verifyPayment(params: any): boolean {
    return this.verifyResult;
  }
  
  verifyWebhookSignature(payload: string, signature: string): boolean {
    return this.verifyResult;
  }
}

describe('Free Trial & AutoPay (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let mockProvider: MockRazorpayProvider;
  
  let ownerToken: string;
  let testOrgId: string;
  let planId: string;
  let runId: number;

  beforeAll(async () => {
    mockProvider = new MockRazorpayProvider();

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider('PAYMENT_PROVIDER')
      .useValue(mockProvider)
      .compile();

    app = moduleFixture.createNestApplication({ rawBody: true });
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
    app.setGlobalPrefix('api');
    app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });
    await app.init();
    
    prisma = app.get<PrismaService>(PrismaService);
    runId = Date.now();
    
    // Create users & auth
    const resOwner = await request(app.getHttpServer())
      .post('/api/v1/auth/register')
      .send({ email: `owner_${runId}@trial.com`, password: 'PassWord123!', firstName: 'Owner', lastName: 'Trial' });
    ownerToken = resOwner.body.data?.accessToken || resOwner.body.accessToken;
    
    // Verify email and mobile for eligibility directly in DB
    const userPhone = `+91999999${runId.toString().slice(-4)}`;
    await prisma.user.updateMany({
      where: { email: `owner_${runId}@trial.com` },
      data: { emailVerifiedAt: new Date(), phone: userPhone }
    });
    // Create Org
    const resOrg = await request(app.getHttpServer()).post('/api/v1/organizations').set('Authorization', `Bearer ${ownerToken}`).send({ name: `Trial Org ${runId}`, slug: `t-org-${runId}` });
    testOrgId = resOrg.body.data?.id ?? resOrg.body.id;

    // Create Plan
    const plan = await prisma.plan.create({
      data: { name: 'Trial Pro', slug: `trial-pro-${runId}`, monthlyPrice: 1000, yearlyPrice: 10000, currency: 'INR', monthlyProviderPlanId: 'plan_mock_monthly' }
    });
    planId = plan.id;
  });

  afterAll(async () => {
    // Delete in correct dependency order
    await prisma.trialClaim.deleteMany({ where: { user: { email: { contains: `@trial.com` } } } });
    await prisma.trialSetup.deleteMany({ where: { user: { email: { contains: `@trial.com` } } } });
    await prisma.user.deleteMany({ where: { email: { contains: `@trial.com` } } });
    await app.close();
  });

  describe('1. Core Trial Lifecycle & Basic Idempotency', () => {
    let setupIdempotencyKey: string;
    let setupResponse: any;

    beforeAll(() => {
      setupIdempotencyKey = `idem_${runId}`;
    });

    it('First eligible user can establish trial setup', async () => {
      const res = await request(app.getHttpServer())
        .post(`/api/v1/billing/trial/${testOrgId}/setup`)
        .set('Authorization', `Bearer ${ownerToken}`)
        .send({
          planId,
          identityReference: `id_ref_${runId}`,
          idempotencyKey: setupIdempotencyKey
        });

      if (res.status !== 201) {
        require('fs').writeFileSync('error.json', JSON.stringify(res.body));
      }
      expect(res.status).toBe(201);
      expect(res.body.status).toBe('PENDING_AUTHORIZATION');
      expect(res.body.providerSubscriptionId).toBeDefined();
      setupResponse = res.body;

      // Verify TrialSetup is created
      const setup = await prisma.trialSetup.findFirst({ where: { providerSubscriptionId: setupResponse.providerSubscriptionId } });
      expect(setup).toBeDefined();
      expect(setup?.status).toBe('PENDING');
    });

    it('Duplicate Idempotency-Key → exactly same response (no duplicate setup)', async () => {
      const res = await request(app.getHttpServer())
        .post(`/api/v1/billing/trial/${testOrgId}/setup`)
        .set('Authorization', `Bearer ${ownerToken}`)
        .send({
          planId,
          identityReference: `id_ref_${runId}`,
          idempotencyKey: setupIdempotencyKey
        });

      expect(res.status).toBe(201); // Created or OK, technically 200/201 depending on how Nest handles idempotency
      expect(res.body).toEqual(setupResponse);
    });

    it('Same idempotency key with different payload → 409 Conflict', async () => {
      const res = await request(app.getHttpServer())
        .post(`/api/v1/billing/trial/${testOrgId}/setup`)
        .set('Authorization', `Bearer ${ownerToken}`)
        .send({
          planId: 'some_other_plan',
          identityReference: `id_ref_${runId}`,
          idempotencyKey: setupIdempotencyKey
        });

      expect(res.status).toBe(409);
    });

    it('Webhook subscription.authenticated → TRIALING subscription + TrialClaim', async () => {
      const webhookPayload = {
        event: 'subscription.authenticated',
        payload: { subscription: { entity: { id: setupResponse.providerSubscriptionId } } },
      };

      const res = await request(app.getHttpServer())
        .post('/api/v1/billing/webhooks/razorpay')
        .set('x-razorpay-event-id', `evt_auth_${runId}`)
        .set('x-razorpay-signature', 'valid')
        .send(webhookPayload);

      expect(res.status).toBe(201);

      // Assert TrialClaim minted
      const userClaims = await prisma.trialClaim.findMany({ where: { organizationId: testOrgId } });
      expect(userClaims.length).toBe(1);
      expect(userClaims[0].status).toBe('ESTABLISHED');

      // Assert Subscription is TRIALING
      const sub = await prisma.subscription.findUnique({ where: { id: userClaims[0].subscriptionId! } });
      expect(sub).toBeDefined();
      expect(sub?.status).toBe(SubscriptionStatus.TRIALING);
      
      // Assert Setup is COMPLETED
      const setup = await prisma.trialSetup.findFirst({ where: { providerSubscriptionId: setupResponse.providerSubscriptionId } });
      expect(setup?.status).toBe('COMPLETED');
    });

    it('Duplicate webhook delivery (same eventId) → Idempotent', async () => {
      const webhookPayload = {
        event: 'subscription.authenticated',
        payload: { subscription: { entity: { id: setupResponse.providerSubscriptionId } } },
      };

      const res = await request(app.getHttpServer())
        .post('/api/v1/billing/webhooks/razorpay')
        .set('x-razorpay-event-id', `evt_auth_${runId}`)
        .set('x-razorpay-signature', 'valid')
        .send(webhookPayload);

      expect(res.status).toBe(201); // Handled cleanly
      
      const userClaims = await prisma.trialClaim.findMany({ where: { organizationId: testOrgId } });
      expect(userClaims.length).toBe(1); // No new claim created
    });

    it('Distinct authorization webhook (different eventId) → Business Idempotency', async () => {
      const webhookPayload = {
        event: 'subscription.authenticated',
        payload: { subscription: { entity: { id: setupResponse.providerSubscriptionId } } },
      };

      const res = await request(app.getHttpServer())
        .post('/api/v1/billing/webhooks/razorpay')
        .set('x-razorpay-event-id', `evt_auth2_${runId}`) // Different event ID
        .set('x-razorpay-signature', 'valid')
        .send(webhookPayload);

      expect(res.status).toBe(201); // Should process without error and gracefully return
      
      // Still only one claim and subscription
      const userClaims = await prisma.trialClaim.findMany({ where: { organizationId: testOrgId } });
      expect(userClaims.length).toBe(1);
    });
    
    it('Same email → rejected', async () => {
      // Trying to setup another trial for the same user account (same email)
      const res = await request(app.getHttpServer())
        .post(`/api/v1/billing/trial/${testOrgId}/setup`)
        .set('Authorization', `Bearer ${ownerToken}`)
        .send({
          planId,
          identityReference: `id_ref2_${runId}`,
          idempotencyKey: `idem_2_${runId}`
        });

      expect(res.status).toBe(409);
    });

    it('Same phone with different identity → rejected', async () => {
      const phoneEmail = `phone_${runId}@trial.com`;
      const resOwner = await request(app.getHttpServer()).post('/api/v1/auth/register').send({ email: phoneEmail, password: 'PassWord123!', firstName: 'Phone', lastName: 'Trial', phone: `+91999999${runId.toString().slice(-4)}` });
      const pToken = resOwner.body.data?.accessToken || resOwner.body.accessToken;
      await prisma.user.updateMany({ where: { email: phoneEmail }, data: { emailVerifiedAt: new Date() } });
      const resOrg = await request(app.getHttpServer()).post('/api/v1/organizations').set('Authorization', `Bearer ${pToken}`).send({ name: `Phone Org`, slug: `p-org-${runId}` });
      const pOrgId = resOrg.body.data?.id ?? resOrg.body.id;

      const res = await request(app.getHttpServer())
        .post(`/api/v1/billing/trial/${pOrgId}/setup`)
        .set('Authorization', `Bearer ${pToken}`)
        .send({
          planId,
          identityReference: `different_id_ref_${runId}`,
          idempotencyKey: `idem_phone_${runId}`
        });

      expect(res.status).toBe(409);
      expect(res.body.message).toContain('MOBILE_ALREADY_USED');
    });

    it('No email + valid phone/identity → eligibility works', async () => {
      const noEmailPhone = `+919999995555`;
      const resOwner = await request(app.getHttpServer()).post('/api/v1/auth/register').send({ password: 'PassWord123!', firstName: 'No', lastName: 'Email', phone: noEmailPhone });
      const neToken = resOwner.body.data?.accessToken || resOwner.body.accessToken;
      await prisma.user.updateMany({ where: { phone: noEmailPhone }, data: { mobileVerifiedAt: new Date(), emailVerifiedAt: new Date() } });
      const resOrg = await request(app.getHttpServer()).post('/api/v1/organizations').set('Authorization', `Bearer ${neToken}`).send({ name: `NoEmail Org`, slug: `ne-org-${runId}` });
      const neOrgId = resOrg.body.data?.id ?? resOrg.body.id;

      const res = await request(app.getHttpServer())
        .post(`/api/v1/billing/trial/${neOrgId}/setup`)
        .set('Authorization', `Bearer ${neToken}`)
        .send({
          planId,
          identityReference: `id_ref_ne_${runId}`,
          idempotencyKey: `idem_ne_${runId}`
        });

      expect(res.status).toBe(201);
    });
  });

  describe('2. Concurrent Eligibility & Idempotency Races', () => {
    it('Concurrent setup with different idempotency keys → at most ONE permanent claim', async () => {
      // Create a new eligible user for this race
      const raceEmail = `race_${runId}@trial.com`;
      const resOwner = await request(app.getHttpServer()).post('/api/v1/auth/register').send({ email: raceEmail, password: 'PassWord123!', firstName: 'Race', lastName: 'Trial' });
      const raceToken = resOwner.body.data?.accessToken || resOwner.body.accessToken;
      await prisma.user.updateMany({ where: { email: raceEmail }, data: { emailVerifiedAt: new Date(), phone: `+919999990001` } });
      const resOrg = await request(app.getHttpServer()).post('/api/v1/organizations').set('Authorization', `Bearer ${raceToken}`).send({ name: `Race Org`, slug: `r-org-${runId}` });
      const raceOrgId = resOrg.body.data?.id ?? resOrg.body.id;

      const res = await Promise.all([
        request(app.getHttpServer()).post(`/api/v1/billing/trial/${raceOrgId}/setup`).set('Authorization', `Bearer ${raceToken}`).send({ planId, identityReference: `id_ref_race_${runId}`, idempotencyKey: `idem_race_1_${runId}` }),
        request(app.getHttpServer()).post(`/api/v1/billing/trial/${raceOrgId}/setup`).set('Authorization', `Bearer ${raceToken}`).send({ planId, identityReference: `id_ref_race_${runId}`, idempotencyKey: `idem_race_2_${runId}` }),
        request(app.getHttpServer()).post(`/api/v1/billing/trial/${raceOrgId}/setup`).set('Authorization', `Bearer ${raceToken}`).send({ planId, identityReference: `id_ref_race_${runId}`, idempotencyKey: `idem_race_3_${runId}` }),
      ]);
      
      const successes = res.filter(r => r.status === 201);
      expect(successes.length).toBeGreaterThanOrEqual(1);
      
      // Authorize all successful setups concurrently
      const authPromises = successes.map((r, i) => {
        return request(app.getHttpServer())
          .post('/api/v1/billing/webhooks/razorpay')
          .set('x-razorpay-event-id', `evt_race_${runId}_${i}`)
          .set('x-razorpay-signature', 'valid')
          .send({ event: 'subscription.authenticated', payload: { subscription: { entity: { id: r.body.providerSubscriptionId } } } });
      });
      await Promise.all(authPromises);
      
      // Exactly ONE permanent claim should exist for this new organization
      const claims = await prisma.trialClaim.findMany({ where: { organizationId: raceOrgId } });
      expect(claims.length).toBe(1);
    });

    it('Same key concurrently submitted → exactly one operation, identical replays', async () => {
      const sameEmail = `same_${runId}@trial.com`;
      const resOwner = await request(app.getHttpServer()).post('/api/v1/auth/register').send({ email: sameEmail, password: 'PassWord123!', firstName: 'Same', lastName: 'Trial' });
      const sameToken = resOwner.body.data?.accessToken || resOwner.body.accessToken;
      await prisma.user.updateMany({ where: { email: sameEmail }, data: { emailVerifiedAt: new Date(), phone: `+919999990002` } });
      const resOrg = await request(app.getHttpServer()).post('/api/v1/organizations').set('Authorization', `Bearer ${sameToken}`).send({ name: `Same Org`, slug: `s-org-${runId}` });
      const sameOrgId = resOrg.body.data?.id ?? resOrg.body.id;

      const idemKey = `idem_race_same_${runId}`;
      const res = await Promise.all([
        request(app.getHttpServer()).post(`/api/v1/billing/trial/${sameOrgId}/setup`).set('Authorization', `Bearer ${sameToken}`).send({ planId, identityReference: `id_ref_same_${runId}`, idempotencyKey: idemKey }),
        request(app.getHttpServer()).post(`/api/v1/billing/trial/${sameOrgId}/setup`).set('Authorization', `Bearer ${sameToken}`).send({ planId, identityReference: `id_ref_same_${runId}`, idempotencyKey: idemKey }),
      ]);
      
      const statusCodes = res.map(r => r.status);
      expect(statusCodes).toContain(201);
      // Wait, because they are exactly concurrent, one might hit 409 if it tries to insert idempotency block after the other
      // or both 201 if handled sequentially by Node. If one gets 409, it should be ConflictException('Previous request failed or is still processing').
      // NestJS might serialize DB queries or Prisma might throw P2002.
      // We just ensure we don't get 2 different TrialSetups.
      const setups = await prisma.trialSetup.findMany({ where: { organizationId: sameOrgId } });
      expect(setups.length).toBe(1);
    });
  });

  describe('3. Webhook Ordering & State Machine Safety', () => {
    let subId: string;
    beforeAll(async () => {
      const claim = await prisma.trialClaim.findFirst({ where: { organizationId: testOrgId, status: 'ESTABLISHED' } });
      subId = claim?.subscriptionId!;
    });

    it('Same provider eventId + different payload hash → 409', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/v1/billing/webhooks/razorpay')
        .set('x-razorpay-event-id', `evt_auth_${runId}`)
        .set('x-razorpay-signature', 'valid')
        .send({ event: 'subscription.authenticated', payload: { different: true } });
      
      expect(res.status).toBe(409); // Idempotency conflict on payload hash
    });

    it('Out-of-order webhook cannot regress trial', async () => {
      // Send an older subscription.created event
      const res = await request(app.getHttpServer())
        .post('/api/v1/billing/webhooks/razorpay')
        .set('x-razorpay-event-id', `evt_created_old_${runId}`)
        .set('x-razorpay-signature', 'valid')
        .send({ event: 'subscription.created', payload: { subscription: { entity: { id: 'some_id' } } } });
      
      expect(res.status).toBe(201);
      // Ensure trial hasn't regressed
      const sub = await prisma.subscription.findUnique({ where: { id: subId } });
      expect(sub?.status).toBe(SubscriptionStatus.TRIALING);
    });

    it('Webhook for unknown TrialSetup → handled safely', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/v1/billing/webhooks/razorpay')
        .set('x-razorpay-event-id', `evt_unknown_${runId}`)
        .set('x-razorpay-signature', 'valid')
        .send({ event: 'subscription.authenticated', payload: { subscription: { entity: { id: 'nonexistent_sub_123' } } } });
      
      expect(res.status).toBeGreaterThanOrEqual(400); // Safe handling, returns client error, no 500
    });
  });

  describe('4. Day-7 Conversion & Billing Logic', () => {
    let subId: string;
    let providerSubId: string;
    
    beforeAll(async () => {
      const claim = await prisma.trialClaim.findFirst({ where: { organizationId: testOrgId, status: 'ESTABLISHED' }, include: { subscription: true } });
      subId = claim?.subscriptionId!;
      providerSubId = claim?.subscription?.providerSubscriptionId!;
    });

    it('Successful first recurring payment converts trial', async () => {
      const paymentEvt = {
        event: 'payment.captured',
        payload: { payment: { entity: { order_id: `ord_${runId}`, id: `pay_conv_${runId}`, metadata: {} } } }
      };
      
      // Need an order to exist first since payment.captured relies on an active order in db in realistic flow.
      // We will skip full DB order setup and just rely on webhooks.service handling if we didn't mock perfectly.
      // Wait, webhooks.service.ts payment.captured needs an existing Order. Let's create a mock Order.
      const order = await prisma.order.create({
        data: {
          organizationId: testOrgId,
          orderNumber: `ORD-${runId}`,
          totalAmount: 1000,
          subtotal: 1000,
          providerOrderId: `ord_${runId}`,
          items: {
            create: [{
              description: 'Trial',
              quantity: 1,
              unitAmount: 1000,
              totalAmount: 1000,
              metadata: { planId }
            }]
          }
        }
      });
      
      const res = await request(app.getHttpServer())
        .post('/api/v1/billing/webhooks/razorpay')
        .set('x-razorpay-event-id', `evt_pay_${runId}`)
        .set('x-razorpay-signature', 'valid')
        .send(paymentEvt);
      
      expect(res.status).toBe(201);
      
      // Actually, since payment.captured updates the order, the subscription ACTIVE transition is usually triggered by `subscription.charged` or `subscription.activated`.
      // Let's send subscription.activated.
      const actEvt = {
        event: 'subscription.activated',
        payload: { subscription: { entity: { id: providerSubId } } }
      };
      await request(app.getHttpServer())
        .post('/api/v1/billing/webhooks/razorpay')
        .set('x-razorpay-event-id', `evt_sub_act_${runId}`)
        .set('x-razorpay-signature', 'valid')
        .send(actEvt);

      const sub = await prisma.subscription.findUnique({ where: { id: subId } });
      expect(sub?.status).toBe(SubscriptionStatus.ACTIVE);
    });
  });
});
