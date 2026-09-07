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
import { Controller, Get, Param, Patch, Body, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { AdminPermissionGuard, RequireAdminPermission } from '../../auth/guards/admin-permission.guard.js';
import { AdminPermissions } from '../constants/admin-permissions.js';
import { AdminUsersService } from '../services/admin-users.service.js';
import { AdminUserQueryDto, AdminUpdateUserDto } from '../dto/admin-users.dto.js';
import { CurrentUser } from '../../auth/decorators/current-user.decorator.js';
let AdminUsersController = class AdminUsersController {
    usersService;
    constructor(usersService) {
        this.usersService = usersService;
    }
    async findAll(query) {
        return this.usersService.findAll(query);
    }
    async findOne(id) {
        return this.usersService.findOne(id);
    }
    async updateUser(actor, id, dto) {
        return this.usersService.updateUser(actor.id, id, dto);
    }
};
__decorate([
    Get(),
    RequireAdminPermission(AdminPermissions.USERS_READ),
    __param(0, Query()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [AdminUserQueryDto]),
    __metadata("design:returntype", Promise)
], AdminUsersController.prototype, "findAll", null);
__decorate([
    Get(':id'),
    RequireAdminPermission(AdminPermissions.USERS_READ),
    __param(0, Param('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AdminUsersController.prototype, "findOne", null);
__decorate([
    Patch(':id'),
    RequireAdminPermission(AdminPermissions.USERS_WRITE),
    __param(0, CurrentUser()),
    __param(1, Param('id')),
    __param(2, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, AdminUpdateUserDto]),
    __metadata("design:returntype", Promise)
], AdminUsersController.prototype, "updateUser", null);
AdminUsersController = __decorate([
    Controller('admin/users'),
    UseGuards(JwtAuthGuard, AdminPermissionGuard),
    __metadata("design:paramtypes", [AdminUsersService])
], AdminUsersController);
export { AdminUsersController };
//# sourceMappingURL=admin-users.controller.js.map