import { Controller, Get, Post, Body, Param, Query, UseGuards, Request } from '@nestjs/common';
import { AdminBillingService } from '../services/admin-billing.service.js';
import { AdminBillingQueryDto, AdminRefundDto } from '../dto/admin-billing.dto.js';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { AdminPermissionGuard, RequireAdminPermission } from '../../auth/guards/admin-permission.guard.js';

@Controller('admin')
@UseGuards(JwtAuthGuard, AdminPermissionGuard)
export class AdminBillingController {
  constructor(private readonly adminBillingService: AdminBillingService) {}

  @Get('subscriptions')
  @RequireAdminPermission('subscriptions.read')
  findAllSubscriptions(@Request() req: any, @Query() query: AdminBillingQueryDto) {
    return this.adminBillingService.findAllSubscriptions(req.user.id, query);
  }

  @Get('subscriptions/:id')
  @RequireAdminPermission('subscriptions.read')
  findOneSubscription(@Request() req: any, @Param('id') id: string) {
    return this.adminBillingService.findOneSubscription(req.user.id, id);
  }

  @Get('orders')
  @RequireAdminPermission('orders.read')
  findAllOrders(@Request() req: any, @Query() query: AdminBillingQueryDto) {
    return this.adminBillingService.findAllOrders(req.user.id, query);
  }

  @Get('orders/:id')
  @RequireAdminPermission('orders.read')
  findOneOrder(@Request() req: any, @Param('id') id: string) {
    return this.adminBillingService.findOneOrder(req.user.id, id);
  }

  @Get('payments')
  @RequireAdminPermission('payments.read')
  findAllPayments(@Request() req: any, @Query() query: AdminBillingQueryDto) {
    return this.adminBillingService.findAllPayments(req.user.id, query);
  }

  @Get('payments/:id')
  @RequireAdminPermission('payments.read')
  findOnePayment(@Request() req: any, @Param('id') id: string) {
    return this.adminBillingService.findOnePayment(req.user.id, id);
  }

  @Get('refunds')
  @RequireAdminPermission('refunds.read')
  findAllRefunds(@Request() req: any, @Query() query: AdminBillingQueryDto) {
    return this.adminBillingService.findAllRefunds(req.user.id, query);
  }

  @Get('refunds/:id')
  @RequireAdminPermission('refunds.read')
  findOneRefund(@Request() req: any, @Param('id') id: string) {
    return this.adminBillingService.findOneRefund(req.user.id, id);
  }

  @Post('payments/:id/refund')
  @RequireAdminPermission('refunds.create')
  refundPayment(@Request() req: any, @Param('id') paymentId: string, @Body() dto: AdminRefundDto) {
    return this.adminBillingService.refundPayment(req.user.id, paymentId, dto);
  }
}
