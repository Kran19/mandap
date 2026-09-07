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
import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { OrgRoleGuard, RequireOrgRole } from '../../auth/guards/org-role.guard.js';
import { MembershipRole } from '@prisma/client';
import { EntitlementService } from '../services/entitlement.service.js';
let EntitlementController = class EntitlementController {
    entitlementService;
    constructor(entitlementService) {
        this.entitlementService = entitlementService;
    }
    async getEntitlement(organizationId) {
        return this.entitlementService.getApplicationAccess(organizationId);
    }
};
__decorate([
    Get(':organizationId'),
    UseGuards(OrgRoleGuard),
    RequireOrgRole(MembershipRole.VIEWER),
    __param(0, Param('organizationId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], EntitlementController.prototype, "getEntitlement", null);
EntitlementController = __decorate([
    Controller('billing/entitlement'),
    UseGuards(JwtAuthGuard),
    __metadata("design:paramtypes", [EntitlementService])
], EntitlementController);
export { EntitlementController };
//# sourceMappingURL=entitlement.controller.js.map