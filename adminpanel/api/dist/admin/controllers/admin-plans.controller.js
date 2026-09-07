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
import { Controller, Get, Post, Patch, Param, Body, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { AdminPermissionGuard, RequireAdminPermission } from '../../auth/guards/admin-permission.guard.js';
import { AdminPermissions } from '../constants/admin-permissions.js';
import { AdminPlansService } from '../services/admin-plans.service.js';
import { AdminPlanQueryDto, AdminCreatePlanDto, AdminUpdatePlanDto } from '../dto/admin-plans.dto.js';
import { CurrentUser } from '../../auth/decorators/current-user.decorator.js';
let AdminPlansController = class AdminPlansController {
    plansService;
    constructor(plansService) {
        this.plansService = plansService;
    }
    findAll(actor, query) {
        return this.plansService.findAll(actor.id, query);
    }
    findOne(actor, id) {
        return this.plansService.findOne(actor.id, id);
    }
    createPlan(actor, dto) {
        return this.plansService.createPlan(actor.id, dto);
    }
    updatePlan(actor, id, dto) {
        return this.plansService.updatePlan(actor.id, id, dto);
    }
};
__decorate([
    Get(),
    RequireAdminPermission(AdminPermissions.PLANS_READ),
    __param(0, CurrentUser()),
    __param(1, Query()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, AdminPlanQueryDto]),
    __metadata("design:returntype", void 0)
], AdminPlansController.prototype, "findAll", null);
__decorate([
    Get(':id'),
    RequireAdminPermission(AdminPermissions.PLANS_READ),
    __param(0, CurrentUser()),
    __param(1, Param('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], AdminPlansController.prototype, "findOne", null);
__decorate([
    Post(),
    RequireAdminPermission(AdminPermissions.PLANS_WRITE),
    __param(0, CurrentUser()),
    __param(1, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, AdminCreatePlanDto]),
    __metadata("design:returntype", void 0)
], AdminPlansController.prototype, "createPlan", null);
__decorate([
    Patch(':id'),
    RequireAdminPermission(AdminPermissions.PLANS_WRITE),
    __param(0, CurrentUser()),
    __param(1, Param('id')),
    __param(2, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, AdminUpdatePlanDto]),
    __metadata("design:returntype", void 0)
], AdminPlansController.prototype, "updatePlan", null);
AdminPlansController = __decorate([
    Controller('admin/plans'),
    UseGuards(JwtAuthGuard, AdminPermissionGuard),
    __metadata("design:paramtypes", [AdminPlansService])
], AdminPlansController);
export { AdminPlansController };
//# sourceMappingURL=admin-plans.controller.js.map