import { Controller, Post, Body, Param, UseGuards, Request, BadRequestException } from '@nestjs/common';
import { OrdersService } from '../services/orders.service.js';
import { PaymentsService } from '../services/payments.service.js';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { OrgRoleGuard, RequireOrgRole } from '../../auth/guards/org-role.guard.js';
import { MembershipRole } from '@prisma/client';

@Controller('billing/checkout')
@UseGuards(JwtAuthGuard, OrgRoleGuard)
export class CheckoutController {
  constructor(
    private readonly ordersService: OrdersService,
    private readonly paymentsService: PaymentsService
  ) {}

  @Post(':organizationId/order')
  @RequireOrgRole(MembershipRole.OWNER) // Only OWNER has billing authority
  async createCheckoutOrder(
    @Request() req: any,
    @Param('organizationId') organizationId: string,
    @Body('planSlug') planSlug: string,
    @Body('interval') interval: 'monthly' | 'yearly'
  ) {
    if (!planSlug || !interval) {
      throw new BadRequestException('planSlug and interval are required');
    }
    return this.ordersService.createCheckoutOrder(organizationId, req.user.id, planSlug, interval);
  }

  @Post(':orgId/verify')
  @RequireOrgRole(MembershipRole.OWNER)
  async verifyPayment(
    @Param('orgId') organizationId: string,
    @Body('providerOrderId') providerOrderId: string,
    @Body('providerPaymentId') providerPaymentId: string,
    @Body('signature') signature: string
  ) {
    if (!providerOrderId || !providerPaymentId || !signature) {
      throw new BadRequestException('Missing payment verification details');
    }
    
    // Server-side verification (transitions Payment and Subscription safely)
    const payment = await this.paymentsService.verifyClientPayment(providerOrderId, providerPaymentId, signature);
    return { success: true, payment };
  }
}
