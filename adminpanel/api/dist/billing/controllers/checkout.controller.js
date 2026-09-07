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
import { Controller, Post, Body, Param, UseGuards, Request, BadRequestException } from '@nestjs/common';
import { OrdersService } from '../services/orders.service.js';
import { PaymentsService } from '../services/payments.service.js';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { OrgRoleGuard, RequireOrgRole } from '../../auth/guards/org-role.guard.js';
import { MembershipRole } from '@prisma/client';
let CheckoutController = class CheckoutController {
    ordersService;
    paymentsService;
    constructor(ordersService, paymentsService) {
        this.ordersService = ordersService;
        this.paymentsService = paymentsService;
    }
    async createCheckoutOrder(req, organizationId, planSlug, interval) {
        if (!planSlug || !interval) {
            throw new BadRequestException('planSlug and interval are required');
        }
        return this.ordersService.createCheckoutOrder(organizationId, req.user.id, planSlug, interval);
    }
    async verifyPayment(organizationId, providerOrderId, providerPaymentId, signature) {
        if (!providerOrderId || !providerPaymentId || !signature) {
            throw new BadRequestException('Missing payment verification details');
        }
        const payment = await this.paymentsService.verifyClientPayment(providerOrderId, providerPaymentId, signature);
        return { success: true, payment };
    }
};
__decorate([
    Post(':organizationId/order'),
    RequireOrgRole(MembershipRole.OWNER),
    __param(0, Request()),
    __param(1, Param('organizationId')),
    __param(2, Body('planSlug')),
    __param(3, Body('interval')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String, String]),
    __metadata("design:returntype", Promise)
], CheckoutController.prototype, "createCheckoutOrder", null);
__decorate([
    Post(':orgId/verify'),
    RequireOrgRole(MembershipRole.OWNER),
    __param(0, Param('orgId')),
    __param(1, Body('providerOrderId')),
    __param(2, Body('providerPaymentId')),
    __param(3, Body('signature')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, String]),
    __metadata("design:returntype", Promise)
], CheckoutController.prototype, "verifyPayment", null);
CheckoutController = __decorate([
    Controller('billing/checkout'),
    UseGuards(JwtAuthGuard, OrgRoleGuard),
    __metadata("design:paramtypes", [OrdersService,
        PaymentsService])
], CheckoutController);
export { CheckoutController };
//# sourceMappingURL=checkout.controller.js.map