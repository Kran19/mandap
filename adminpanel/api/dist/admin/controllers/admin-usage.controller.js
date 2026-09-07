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
import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { AdminPermissionGuard, RequireAdminPermission } from '../../auth/guards/admin-permission.guard.js';
import { AdminPermissions } from '../constants/admin-permissions.js';
import { AdminUsageService } from '../services/admin-usage.service.js';
import { AdminUsageQueryDto } from '../dto/admin-usage.dto.js';
import { CurrentUser } from '../../auth/decorators/current-user.decorator.js';
let AdminUsageController = class AdminUsageController {
    usageService;
    constructor(usageService) {
        this.usageService = usageService;
    }
    findAll(actor, query) {
        return this.usageService.findAll(actor.id, query);
    }
    findByOrg(actor, orgId, query) {
        return this.usageService.findAll(actor.id, { ...query, organizationId: orgId });
    }
};
__decorate([
    Get(),
    RequireAdminPermission(AdminPermissions.USAGE_READ),
    __param(0, CurrentUser()),
    __param(1, Query()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, AdminUsageQueryDto]),
    __metadata("design:returntype", void 0)
], AdminUsageController.prototype, "findAll", null);
__decorate([
    Get(':organizationId'),
    RequireAdminPermission(AdminPermissions.USAGE_READ),
    __param(0, CurrentUser()),
    __param(1, Param('organizationId')),
    __param(2, Query()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, AdminUsageQueryDto]),
    __metadata("design:returntype", void 0)
], AdminUsageController.prototype, "findByOrg", null);
AdminUsageController = __decorate([
    Controller('admin/usage'),
    UseGuards(JwtAuthGuard, AdminPermissionGuard),
    __metadata("design:paramtypes", [AdminUsageService])
], AdminUsageController);
export { AdminUsageController };
//# sourceMappingURL=admin-usage.controller.js.map