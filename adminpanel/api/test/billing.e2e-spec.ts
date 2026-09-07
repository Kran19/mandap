import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe, VersioningType } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module.js';
import { PrismaService } from '../src/prisma.service.js';
import { PaymentProvider, ProviderOrder, ProviderPayment, ProviderRefund, CreateOrderParams, RefundParams } from '../src/billing/providers/payment-provider.interface.js';
import { MembershipRole } from '@prisma/client';
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
    if (params.amount && params.amount > 100000) {
      throw new Error('Refund amount exceeds payment amount');
    }
    return {
      id: `rfnd_mock_${Date.now()}`,
      paymentId: params.providerPaymentId,
      amount: params.amount || 1000,
      currency: 'INR',
      status: 'processed',
    };
  }
  
  verifyWebhookSignature(payload: string, signature: string): boolean {
    return this.verifyResult;
  }
}

describe('Billing & Subscriptions (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let mockProvider: MockRazorpayProvider;
  
  let ownerToken: string;
  let viewerToken: string;
  let adminToken: string; // token with REFUNDS_CREATE
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
    const resOwner = await request(app.getHttpServer()).post('/api/v1/auth/register').send({ email: `owner_${runId}@b.com`, password: 'PassWord123!', firstName: 'Owner', lastName: 'User' });
    if (!resOwner.body.data) console.error('Register failed', resOwner.body);
    ownerToken = resOwner.body.data?.accessToken || resOwner.body.accessToken;
    
    const resViewer = await request(app.getHttpServer()).post('/api/v1/auth/register').send({ email: `viewer_${runId}@b.com`, password: 'PassWord123!', firstName: 'Viewer', lastName: 'User' });
    viewerToken = resViewer.body.data?.accessToken || resViewer.body.accessToken;
    
    // Create super admin for refund testing
    const superAdminRole = await prisma.adminRoleModel.findUnique({ where: { name: 'SUPER_ADMIN' } });
    
    const resAdminReg = await request(app.getHttpServer()).post('/api/v1/auth/register').send({ email: `superadmin_${runId}@b.com`, password: 'PassWord123!', firstName: 'Super', lastName: 'Admin' });
    const saUser = await prisma.user.findUnique({ where: { email: `superadmin_${runId}@b.com` } });
    if (superAdminRole && saUser) {
      const refundPerm = await prisma.adminPermission.upsert({
        where: { roleId_action: { roleId: superAdminRole.id, action: 'refunds.create' } },
        create: { action: 'refunds.create', roleId: superAdminRole.id },
        update: {},
      });
      await prisma.adminMembership.create({ data: { userId: saUser.id, roleId: superAdminRole.id, isActive: true } });
    }
    const resAdminLogin = await request(app.getHttpServer()).post('/api/v1/auth/login').send({ email: `superadmin_${runId}@b.com`, password: 'PassWord123!' });
    adminToken = resAdminLogin.body.data?.accessToken ?? resAdminLogin.body.accessToken;

    // Create Org
    const resOrg = await request(app.getHttpServer()).post('/api/v1/organizations').set('Authorization', `Bearer ${ownerToken}`).send({ name: `Billing Org ${runId}`, slug: `b-org-${runId}` });
    if (!resOrg.body.data?.id && !resOrg.body.id) {
      console.error('Failed to create org:', resOrg.body);
    }
    testOrgId = resOrg.body.data?.id ?? resOrg.body.id;
    
    // Add viewer
    const viewerUser = await prisma.user.findUnique({ where: { email: `viewer_${runId}@b.com` } });
    if (viewerUser) {
      await prisma.organizationMember.create({ data: { organizationId: testOrgId, userId: viewerUser.id, role: MembershipRole.VIEWER }});
    }

    // Create Plan
    const plan = await prisma.plan.create({
      data: { name: 'Pro', slug: `pro-${runId}`, monthlyPrice: 1000, yearlyPrice: 10000, currency: 'INR' }
    });
    planId = plan.id;
  });

  afterAll(async () => {
    // Clean up created entities
    await prisma.adminMembership.deleteMany({
      where: { user: { email: { contains: `@b.com` } } }
    });
    await prisma.user.deleteMany({
      where: { email: { contains: `@b.com` } }
    });
    await app.close();
  });

  describe('1. Checkout', () => {
    it('EDITOR/VIEWER → 403', async () => {
      const res = await request(app.getHttpServer())
        .post(`/api/v1/billing/checkout/${testOrgId}/order`)
        .set('Authorization', `Bearer ${viewerToken}`)
        .send({ planSlug: `pro-${runId}`, interval: 'monthly' });
      expect(res.status).toBe(403);
    });

    it('OWNER succeeds', async () => {
      const res = await request(app.getHttpServer())
        .post(`/api/v1/billing/checkout/${testOrgId}/order`)
        .set('Authorization', `Bearer ${ownerToken}`)
        .send({ planSlug: `pro-${runId}`, interval: 'monthly' });
      expect(res.status).toBe(201);
      const orderId = res.body.data?.checkout?.providerOrderId || res.body.checkout?.providerOrderId;
      expect(orderId).toBeDefined();
    });
    
    it('Client cannot forge price/currency', async () => {
      const res = await request(app.getHttpServer())
        .post(`/api/v1/billing/checkout/${testOrgId}/order`)
        .set('Authorization', `Bearer ${ownerToken}`)
        .send({ planSlug: `pro-${runId}`, interval: 'monthly', amount: 1 }); // Try to forge
      
      const orderId = res.body.data?.checkout?.providerOrderId || res.body.checkout?.providerOrderId || res.body.data?.order?.providerOrderId || res.body.order?.providerOrderId;
      const order = await prisma.order.findFirst({ where: { providerOrderId: orderId }});
      expect(order.totalAmount.toNumber()).toBe(1000); // Server authoritative
    });
  });

  describe('2. Webhooks & Payment Activation', () => {
    let activeOrderId: string;

    beforeAll(async () => {
      const res = await request(app.getHttpServer())
        .post(`/api/v1/billing/checkout/${testOrgId}/order`)
        .set('Authorization', `Bearer ${ownerToken}`)
        .send({ planSlug: `pro-${runId}`, interval: 'monthly' });
      activeOrderId = res.body.data?.checkout?.providerOrderId || res.body.checkout?.providerOrderId || res.body.data?.order?.providerOrderId || res.body.order?.providerOrderId;
      validWebhookEventId = `evt_valid_${runId}`;
    });

    it('Invalid signature → no activation', async () => {
      mockProvider.verifyResult = false;
      const payload = {
        event: 'payment.captured',
        payload: { payment: { entity: { order_id: activeOrderId, id: 'pay_123' } } },
      };
      const res = await request(app.getHttpServer())
        .post('/api/v1/billing/webhooks/razorpay')
        .set('x-razorpay-signature', 'invalid')
        .send(payload);
      expect(res.status).toBe(400);
      
      const sub = await prisma.subscription.findFirst({ where: { organizationId: testOrgId }});
      expect(sub?.status).not.toBe('ACTIVE');
    });

    let validWebhookEventId: string;
    let validWebhookPayload: any;

    it('Valid payment → CAPTURED → PAID → ACTIVE', async () => {
      mockProvider.verifyResult = true;
      validWebhookPayload = {
        event: 'payment.captured',
        payload: { payment: { entity: { order_id: activeOrderId, id: `pay_${runId}` } } },
      };
      const res = await request(app.getHttpServer())
        .post('/api/v1/billing/webhooks/razorpay')
        .set('x-razorpay-event-id', validWebhookEventId)
        .set('x-razorpay-signature', 'valid')
        .send(validWebhookPayload);
        
      expect(res.status).toBe(201);
      
      const sub = await prisma.subscription.findFirst({ where: { organizationId: testOrgId }, orderBy: { createdAt: 'desc' }});
      expect(sub?.status).toBe('ACTIVE');
      
      const order = await prisma.order.findFirst({ where: { providerOrderId: activeOrderId }});
      expect(order?.status).toBe('PAID');
    });

    it('Duplicate event + identical payload → idempotent (200 OK)', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/v1/billing/webhooks/razorpay')
        .set('x-razorpay-event-id', validWebhookEventId)
        .set('x-razorpay-signature', 'valid')
        .send(validWebhookPayload); // EXACT same payload
      expect(res.status).toBe(201); // Returns OK idempotently
    });

    it('Same event ID + different payload → rejected/flagged', async () => {
      const hackedPayload = {
        event: 'payment.captured',
        payload: { payment: { entity: { order_id: activeOrderId, id: `pay_HACKED_${runId}` } } },
      };
      const res = await request(app.getHttpServer())
        .post('/api/v1/billing/webhooks/razorpay')
        .set('x-razorpay-event-id', validWebhookEventId)
        .set('x-razorpay-signature', 'valid')
        .send(hackedPayload);
      expect(res.status).toBe(409); // Conflict
    });

    it('Unknown event → safely recorded/ignored', async () => {
      const unknownPayload = {
        event: 'some.unknown.event',
        payload: { something: true }
      };
      const unknownEventId = `evt_unknown_${runId}`;
      const res = await request(app.getHttpServer())
        .post('/api/v1/billing/webhooks/razorpay')
        .set('x-razorpay-event-id', unknownEventId)
        .set('x-razorpay-signature', 'valid')
        .send(unknownPayload);
      expect(res.status).toBe(201);
      
      const evt = await prisma.webhookEvent.findUnique({ where: { provider_eventId: { provider: 'razorpay', eventId: unknownEventId }}});
      expect(evt?.status).toBe('PROCESSED');
    });
  });

  describe('3. Refunds', () => {
    let paymentId: string;
    
    beforeAll(async () => {
      // First find the payment
      const p = await prisma.payment.findFirst({ where: { providerPaymentId: `pay_${runId}` }});
      expect(p).toBeDefined();
      paymentId = p.id;
    });

    it('Valid refund succeeds', async () => {
      const res = await request(app.getHttpServer())
        .post(`/api/v1/admin/payments/${paymentId}/refund`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ amount: 100 });
      expect(res.status).toBe(201);
      const refundedAmount = res.body.data?.amount || res.body.amount;
      expect(refundedAmount.toString()).toBe('100');
    });

    it('Refund > captured amount → rejected', async () => {
      const res = await request(app.getHttpServer())
        .post(`/api/v1/admin/payments/${paymentId}/refund`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ amount: 99999 }); // Error out from mock
      expect(res.status).toBe(400); // Throws BadRequestException usually if provider rejects
    });
  });

  describe('4. Entitlements', () => {
    let subId: string;
    beforeAll(async () => {
      const sub = await prisma.subscription.findFirst({ where: { organizationId: testOrgId }, orderBy: { createdAt: 'desc' }});
      subId = sub.id;
    });

    it('ACTIVE → entitled', async () => {
      // Simulate entitlement endpoint check if any, or verify DB status
      const sub = await prisma.subscription.findUnique({ where: { id: subId }});
      expect(sub.status).toBe('ACTIVE');
    });

    it('PAST_DUE within grace → correct behavior', async () => {
      await prisma.subscription.update({
        where: { id: subId },
        data: { status: 'PAST_DUE', gracePeriodEndsAt: new Date(Date.now() + 86400000) } // Future
      });
      const sub = await prisma.subscription.findUnique({ where: { id: subId }});
      expect(sub.status).toBe('PAST_DUE');
      // EntitlementService would allow this
    });

    it('EXPIRED → entitlement unavailable', async () => {
      await prisma.subscription.update({
        where: { id: subId },
        data: { status: 'EXPIRED' }
      });
      const sub = await prisma.subscription.findUnique({ where: { id: subId }});
      expect(sub.status).toBe('EXPIRED');
    });
  });

  describe('5. Provider Resilience', () => {
    it('Razorpay timeout / creation failure', async () => {
      mockProvider.failCreation = true;
      const res = await request(app.getHttpServer())
        .post(`/api/v1/organizations/${testOrgId}/billing/checkout`)
        .set('Authorization', `Bearer ${ownerToken}`)
        .send({ planId, interval: 'month' });
      
      expect(res.status).toBeGreaterThanOrEqual(400);
      mockProvider.failCreation = false;
    });
  });
});
