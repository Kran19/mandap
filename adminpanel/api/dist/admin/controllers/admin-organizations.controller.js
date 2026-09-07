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
import { Controller, Get, Param, UseGuards, Query, Patch, Body } from '@nestjs/common';
import { AdminOrganizationsService } from '../services/admin-organizations.service.js';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { AdminPermissionGuard, RequireAdminPermission } from '../../auth/guards/admin-permission.guard.js';
import { AdminPermissions } from '../constants/admin-permissions.js';
import { CurrentUser } from '../../auth/decorators/current-user.decorator.js';
import { AdminOrganizationQueryDto, AdminUpdateOrganizationDto } from '../dto/admin-organizations.dto.js';
let AdminOrganizationsController = class AdminOrganizationsController {
    adminOrganizationsService;
    constructor(adminOrganizationsService) {
        this.adminOrganizationsService = adminOrganizationsService;
    }
    findAll(user, query) {
        return this.adminOrganizationsService.findAll(user.id, query);
    }
    getOrganization(user, id) {
        return this.adminOrganizationsService.getOrganization(user.id, id);
    }
    updateOrganization(user, id, dto) {
        return this.adminOrganizationsService.updateOrganization(user.id, id, dto);
    }
};
__decorate([
    Get(),
    RequireAdminPermission(AdminPermissions.ORGANIZATIONS_READ),
    __param(0, CurrentUser()),
    __param(1, Query()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, AdminOrganizationQueryDto]),
    __metadata("design:returntype", void 0)
], AdminOrganizationsController.prototype, "findAll", null);
__decorate([
    Get(':id'),
    RequireAdminPermission(AdminPermissions.ORGANIZATIONS_READ),
    __param(0, CurrentUser()),
    __param(1, Param('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], AdminOrganizationsController.prototype, "getOrganization", null);
__decorate([
    Patch(':id'),
    RequireAdminPermission(AdminPermissions.ORGANIZATIONS_WRITE),
    __param(0, CurrentUser()),
    __param(1, Param('id')),
    __param(2, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, AdminUpdateOrganizationDto]),
    __metadata("design:returntype", void 0)
], AdminOrganizationsController.prototype, "updateOrganization", null);
AdminOrganizationsController = __decorate([
    Controller('admin/organizations'),
    UseGuards(JwtAuthGuard, AdminPermissionGuard),
    __metadata("design:paramtypes", [AdminOrganizationsService])
], AdminOrganizationsController);
export { AdminOrganizationsController };
//# sourceMappingURL=admin-organizations.controller.js.map