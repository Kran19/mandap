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
import { Controller, Get, Post, Body, Param, Query, UseGuards, Request } from '@nestjs/common';
import { AdminBillingService } from '../services/admin-billing.service.js';
import { AdminBillingQueryDto, AdminRefundDto } from '../dto/admin-billing.dto.js';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { AdminPermissionGuard, RequireAdminPermission } from '../../auth/guards/admin-permission.guard.js';
let AdminBillingController = class AdminBillingController {
    adminBillingService;
    constructor(adminBillingService) {
        this.adminBillingService = adminBillingService;
    }
    findAllSubscriptions(req, query) {
        return this.adminBillingService.findAllSubscriptions(req.user.id, query);
    }
    findOneSubscription(req, id) {
        return this.adminBillingService.findOneSubscription(req.user.id, id);
    }
    findAllOrders(req, query) {
        return this.adminBillingService.findAllOrders(req.user.id, query);
    }
    findOneOrder(req, id) {
        return this.adminBillingService.findOneOrder(req.user.id, id);
    }
    findAllPayments(req, query) {
        return this.adminBillingService.findAllPayments(req.user.id, query);
    }
    findOnePayment(req, id) {
        return this.adminBillingService.findOnePayment(req.user.id, id);
    }
    findAllRefunds(req, query) {
        return this.adminBillingService.findAllRefunds(req.user.id, query);
    }
    findOneRefund(req, id) {
        return this.adminBillingService.findOneRefund(req.user.id, id);
    }
    refundPayment(req, paymentId, dto) {
        return this.adminBillingService.refundPayment(req.user.id, paymentId, dto);
    }
};
__decorate([
    Get('subscriptions'),
    RequireAdminPermission('subscriptions.read'),
    __param(0, Request()),
    __param(1, Query()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, AdminBillingQueryDto]),
    __metadata("design:returntype", void 0)
], AdminBillingController.prototype, "findAllSubscriptions", null);
__decorate([
    Get('subscriptions/:id'),
    RequireAdminPermission('subscriptions.read'),
    __param(0, Request()),
    __param(1, Param('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], AdminBillingController.prototype, "findOneSubscription", null);
__decorate([
    Get('orders'),
    RequireAdminPermission('orders.read'),
    __param(0, Request()),
    __param(1, Query()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, AdminBillingQueryDto]),
    __metadata("design:returntype", void 0)
], AdminBillingController.prototype, "findAllOrders", null);
__decorate([
    Get('orders/:id'),
    RequireAdminPermission('orders.read'),
    __param(0, Request()),
    __param(1, Param('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], AdminBillingController.prototype, "findOneOrder", null);
__decorate([
    Get('payments'),
    RequireAdminPermission('payments.read'),
    __param(0, Request()),
    __param(1, Query()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, AdminBillingQueryDto]),
    __metadata("design:returntype", void 0)
], AdminBillingController.prototype, "findAllPayments", null);
__decorate([
    Get('payments/:id'),
    RequireAdminPermission('payments.read'),
    __param(0, Request()),
    __param(1, Param('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], AdminBillingController.prototype, "findOnePayment", null);
__decorate([
    Get('refunds'),
    RequireAdminPermission('refunds.read'),
    __param(0, Request()),
    __param(1, Query()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, AdminBillingQueryDto]),
    __metadata("design:returntype", void 0)
], AdminBillingController.prototype, "findAllRefunds", null);
__decorate([
    Get('refunds/:id'),
    RequireAdminPermission('refunds.read'),
    __param(0, Request()),
    __param(1, Param('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], AdminBillingController.prototype, "findOneRefund", null);
__decorate([
    Post('payments/:id/refund'),
    RequireAdminPermission('refunds.create'),
    __param(0, Request()),
    __param(1, Param('id')),
    __param(2, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, AdminRefundDto]),
    __metadata("design:returntype", void 0)
], AdminBillingController.prototype, "refundPayment", null);
AdminBillingController = __decorate([
    Controller('admin'),
    UseGuards(JwtAuthGuard, AdminPermissionGuard),
    __metadata("design:paramtypes", [AdminBillingService])
], AdminBillingController);
export { AdminBillingController };
//# sourceMappingURL=admin-billing.controller.js.map