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
import { AdminPermissionGuard, RequireAdminPermission } from '../../auth/guards/admin-permission.guard.js';
import { AdminPermissions } from '../constants/admin-permissions.js';
let AdminPermissionsController = class AdminPermissionsController {
    findAll() {
        return Object.values(AdminPermissions).map(action => ({ action }));
    }
    findOne(action) {
        if (Object.values(AdminPermissions).includes(action)) {
            return { action };
        }
        return null;
    }
};
__decorate([
    Get(),
    RequireAdminPermission(AdminPermissions.PERMISSIONS_READ),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], AdminPermissionsController.prototype, "findAll", null);
__decorate([
    Get(':id'),
    RequireAdminPermission(AdminPermissions.PERMISSIONS_READ),
    __param(0, Param('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], AdminPermissionsController.prototype, "findOne", null);
AdminPermissionsController = __decorate([
    Controller('admin/permissions'),
    UseGuards(JwtAuthGuard, AdminPermissionGuard)
], AdminPermissionsController);
export { AdminPermissionsController };
//# sourceMappingURL=admin-permissions.controller.js.map