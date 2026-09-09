import { Controller, Get, Post, Body, Param, Query, UseGuards, Request } from '@nestjs/common';
import { AdminBillingService } from '../services/admin-billing.service.js';
import { AdminBillingQueryDto, AdminRefundDto } from '../dto/admin-billing.dto.js';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { AdminPermissionGuard, RequireAdminPermission } from '../../auth/guards/admin-permission.guard.js';
import { AdminPermissions } from '../constants/admin-permissions.js';

@Controller('admin')
@UseGuards(JwtAuthGuard, AdminPermissionGuard)
export class AdminBillingController {
  constructor(private readonly adminBillingService: AdminBillingService) {}

  @Get('subscriptions')
  @RequireAdminPermission(AdminPermissions.SUBSCRIPTIONS_READ)
  findAllSubscriptions(@Request() req: any, @Query() query: AdminBillingQueryDto) {
    return this.adminBillingService.findAllSubscriptions(req.user.id, query);
  }

  @Get('subscriptions/:id')
  @RequireAdminPermission(AdminPermissions.SUBSCRIPTIONS_READ)
  findOneSubscription(@Request() req: any, @Param('id') id: string) {
    return this.adminBillingService.findOneSubscription(req.user.id, id);
  }

  @Get('orders')
  @RequireAdminPermission(AdminPermissions.ORDERS_READ)
  findAllOrders(@Request() req: any, @Query() query: AdminBillingQueryDto) {
    return this.adminBillingService.findAllOrders(req.user.id, query);
  }

  @Get('orders/:id')
  @RequireAdminPermission(AdminPermissions.ORDERS_READ)
  findOneOrder(@Request() req: any, @Param('id') id: string) {
    return this.adminBillingService.findOneOrder(req.user.id, id);
  }

  @Get('payments')
  @RequireAdminPermission(AdminPermissions.PAYMENTS_READ)
  findAllPayments(@Request() req: any, @Query() query: AdminBillingQueryDto) {
    return this.adminBillingService.findAllPayments(req.user.id, query);
  }

  @Get('payments/:id')
  @RequireAdminPermission(AdminPermissions.PAYMENTS_READ)
  findOnePayment(@Request() req: any, @Param('id') id: string) {
    return this.adminBillingService.findOnePayment(req.user.id, id);
  }

  @Get('refunds')
  @RequireAdminPermission(AdminPermissions.REFUNDS_READ)
  findAllRefunds(@Request() req: any, @Query() query: AdminBillingQueryDto) {
    return this.adminBillingService.findAllRefunds(req.user.id, query);
  }

  @Get('refunds/:id')
  @RequireAdminPermission(AdminPermissions.REFUNDS_READ)
  findOneRefund(@Request() req: any, @Param('id') id: string) {
    return this.adminBillingService.findOneRefund(req.user.id, id);
  }

  @Post('payments/:id/refund')
  @RequireAdminPermission(AdminPermissions.REFUNDS_CREATE)
  refundPayment(@Request() req: any, @Param('id') paymentId: string, @Body() dto: AdminRefundDto) {
    return this.adminBillingService.refundPayment(req.user.id, paymentId, dto);
  }
}
