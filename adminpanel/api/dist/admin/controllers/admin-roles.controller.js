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
import { AdminRolesService } from '../services/admin-roles.service.js';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { AdminPermissionGuard, RequireAdminPermission } from '../../auth/guards/admin-permission.guard.js';
import { AdminPermissions } from '../constants/admin-permissions.js';
import { AdminRoleQueryDto, AdminCreateRoleDto, AdminUpdateRoleDto } from '../dto/admin-roles.dto.js';
import { CurrentUser } from '../../auth/decorators/current-user.decorator.js';
let AdminRolesController = class AdminRolesController {
    adminRolesService;
    constructor(adminRolesService) {
        this.adminRolesService = adminRolesService;
    }
    findAll(user, query) {
        return this.adminRolesService.findAll(user.id, query);
    }
    findOne(user, id) {
        return this.adminRolesService.findOne(user.id, id);
    }
    createRole(user, dto) {
        return this.adminRolesService.createRole(user.id, dto);
    }
    updateRole(user, id, dto) {
        return this.adminRolesService.updateRole(user.id, id, dto);
    }
    grantSuperAdmin(user, targetUserId) {
        return this.adminRolesService.grantSuperAdmin(user.id, targetUserId);
    }
    revokeSuperAdmin(user, targetUserId) {
        return this.adminRolesService.revokeSuperAdmin(user.id, targetUserId);
    }
};
__decorate([
    Get(),
    RequireAdminPermission(AdminPermissions.ROLES_READ),
    __param(0, CurrentUser()),
    __param(1, Query()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, AdminRoleQueryDto]),
    __metadata("design:returntype", void 0)
], AdminRolesController.prototype, "findAll", null);
__decorate([
    Get(':id'),
    RequireAdminPermission(AdminPermissions.ROLES_READ),
    __param(0, CurrentUser()),
    __param(1, Param('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], AdminRolesController.prototype, "findOne", null);
__decorate([
    Post(),
    RequireAdminPermission(AdminPermissions.ROLES_WRITE),
    __param(0, CurrentUser()),
    __param(1, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, AdminCreateRoleDto]),
    __metadata("design:returntype", void 0)
], AdminRolesController.prototype, "createRole", null);
__decorate([
    Patch(':id'),
    RequireAdminPermission(AdminPermissions.ROLES_WRITE),
    __param(0, CurrentUser()),
    __param(1, Param('id')),
    __param(2, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, AdminUpdateRoleDto]),
    __metadata("design:returntype", void 0)
], AdminRolesController.prototype, "updateRole", null);
__decorate([
    Post('grant-super-admin/:userId'),
    RequireAdminPermission(AdminPermissions.ROLES_WRITE),
    __param(0, CurrentUser()),
    __param(1, Param('userId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], AdminRolesController.prototype, "grantSuperAdmin", null);
__decorate([
    Post('revoke-super-admin/:userId'),
    RequireAdminPermission(AdminPermissions.ROLES_WRITE),
    __param(0, CurrentUser()),
    __param(1, Param('userId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], AdminRolesController.prototype, "revokeSuperAdmin", null);
AdminRolesController = __decorate([
    Controller('admin/roles'),
    UseGuards(JwtAuthGuard, AdminPermissionGuard),
    __metadata("design:paramtypes", [AdminRolesService])
], AdminRolesController);
export { AdminRolesController };
//# sourceMappingURL=admin-roles.controller.js.map