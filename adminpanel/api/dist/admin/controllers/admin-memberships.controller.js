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
import { Controller, Get, Param, Post, Patch, Delete, Body, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { AdminPermissionGuard, RequireAdminPermission } from '../../auth/guards/admin-permission.guard.js';
import { AdminPermissions } from '../constants/admin-permissions.js';
import { AdminMembershipsService } from '../services/admin-memberships.service.js';
import { AdminMembershipQueryDto, AdminAddMembershipDto, AdminUpdateMembershipDto } from '../dto/admin-memberships.dto.js';
import { CurrentUser } from '../../auth/decorators/current-user.decorator.js';
let AdminMembershipsController = class AdminMembershipsController {
    membershipsService;
    constructor(membershipsService) {
        this.membershipsService = membershipsService;
    }
    async findAll(actor, orgId, query) {
        return this.membershipsService.findAll(actor.id, orgId, query);
    }
    async addMember(actor, orgId, dto) {
        return this.membershipsService.addMember(actor.id, orgId, dto);
    }
    async updateMemberRole(actor, orgId, userId, dto) {
        return this.membershipsService.updateMemberRole(actor.id, orgId, userId, dto);
    }
    async removeMember(actor, orgId, userId) {
        return this.membershipsService.removeMember(actor.id, orgId, userId);
    }
};
__decorate([
    Get(),
    RequireAdminPermission(AdminPermissions.MEMBERSHIPS_READ),
    __param(0, CurrentUser()),
    __param(1, Param('orgId')),
    __param(2, Query()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, AdminMembershipQueryDto]),
    __metadata("design:returntype", Promise)
], AdminMembershipsController.prototype, "findAll", null);
__decorate([
    Post(),
    RequireAdminPermission(AdminPermissions.MEMBERSHIPS_WRITE),
    __param(0, CurrentUser()),
    __param(1, Param('orgId')),
    __param(2, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, AdminAddMembershipDto]),
    __metadata("design:returntype", Promise)
], AdminMembershipsController.prototype, "addMember", null);
__decorate([
    Patch(':userId'),
    RequireAdminPermission(AdminPermissions.MEMBERSHIPS_WRITE),
    __param(0, CurrentUser()),
    __param(1, Param('orgId')),
    __param(2, Param('userId')),
    __param(3, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String, AdminUpdateMembershipDto]),
    __metadata("design:returntype", Promise)
], AdminMembershipsController.prototype, "updateMemberRole", null);
__decorate([
    Delete(':userId'),
    RequireAdminPermission(AdminPermissions.MEMBERSHIPS_WRITE),
    __param(0, CurrentUser()),
    __param(1, Param('orgId')),
    __param(2, Param('userId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", Promise)
], AdminMembershipsController.prototype, "removeMember", null);
AdminMembershipsController = __decorate([
    Controller('admin/organizations/:orgId/members'),
    UseGuards(JwtAuthGuard, AdminPermissionGuard),
    __metadata("design:paramtypes", [AdminMembershipsService])
], AdminMembershipsController);
export { AdminMembershipsController };
//# sourceMappingURL=admin-memberships.controller.js.map