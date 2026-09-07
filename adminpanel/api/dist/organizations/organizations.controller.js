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
import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards, Request, HttpCode, HttpStatus } from '@nestjs/common';
import { OrganizationsService } from './organizations.service.js';
import { MembershipsService } from './memberships.service.js';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { OrgRoleGuard, RequireOrgRole } from '../auth/guards/org-role.guard.js';
import { CreateOrganizationDto } from './dto/create-organization.dto.js';
import { UpdateOrganizationDto } from './dto/update-organization.dto.js';
import { AddMemberDto } from './dto/add-member.dto.js';
import { UpdateMemberRoleDto } from './dto/update-member-role.dto.js';
import { TransferOwnershipDto } from './dto/transfer-ownership.dto.js';
import { MembershipRole } from '@prisma/client';
let OrganizationsController = class OrganizationsController {
    organizationsService;
    membershipsService;
    constructor(organizationsService, membershipsService) {
        this.organizationsService = organizationsService;
        this.membershipsService = membershipsService;
    }
    create(req, dto) {
        return this.organizationsService.createOrganization(req.user.id, dto);
    }
    findAll(req) {
        return this.organizationsService.getUserOrganizations(req.user.id);
    }
    findOne(organizationId) {
        return this.organizationsService.getOrganization(organizationId);
    }
    update(organizationId, dto) {
        return this.organizationsService.updateOrganization(organizationId, dto);
    }
    getMembers(organizationId) {
        return this.membershipsService.getMembers(organizationId);
    }
    addMember(organizationId, dto) {
        return this.membershipsService.addMember(organizationId, dto);
    }
    updateMemberRole(organizationId, targetUserId, dto) {
        return this.membershipsService.updateMemberRole(organizationId, targetUserId, dto);
    }
    removeMember(organizationId, targetUserId) {
        return this.membershipsService.removeMember(organizationId, targetUserId);
    }
    transferOwnership(organizationId, req, dto) {
        return this.membershipsService.transferOwnership(organizationId, req.user.id, dto.newOwnerId);
    }
    leaveOrganization(organizationId, req) {
        return this.membershipsService.leaveOrganization(organizationId, req.user.id);
    }
};
__decorate([
    Post(),
    __param(0, Request()),
    __param(1, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, CreateOrganizationDto]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "create", null);
__decorate([
    Get(),
    __param(0, Request()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "findAll", null);
__decorate([
    Get(':organizationId'),
    UseGuards(OrgRoleGuard),
    __param(0, Param('organizationId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "findOne", null);
__decorate([
    Patch(':organizationId'),
    UseGuards(OrgRoleGuard),
    RequireOrgRole(MembershipRole.OWNER),
    __param(0, Param('organizationId')),
    __param(1, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, UpdateOrganizationDto]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "update", null);
__decorate([
    Get(':organizationId/members'),
    UseGuards(OrgRoleGuard),
    __param(0, Param('organizationId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "getMembers", null);
__decorate([
    Post(':organizationId/members'),
    UseGuards(OrgRoleGuard),
    RequireOrgRole(MembershipRole.OWNER),
    __param(0, Param('organizationId')),
    __param(1, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, AddMemberDto]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "addMember", null);
__decorate([
    Patch(':organizationId/members/:userId'),
    UseGuards(OrgRoleGuard),
    RequireOrgRole(MembershipRole.OWNER),
    __param(0, Param('organizationId')),
    __param(1, Param('userId')),
    __param(2, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, UpdateMemberRoleDto]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "updateMemberRole", null);
__decorate([
    Delete(':organizationId/members/:userId'),
    UseGuards(OrgRoleGuard),
    RequireOrgRole(MembershipRole.OWNER),
    __param(0, Param('organizationId')),
    __param(1, Param('userId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "removeMember", null);
__decorate([
    Post(':organizationId/ownership-transfer'),
    HttpCode(HttpStatus.OK),
    UseGuards(OrgRoleGuard),
    RequireOrgRole(MembershipRole.OWNER),
    __param(0, Param('organizationId')),
    __param(1, Request()),
    __param(2, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, TransferOwnershipDto]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "transferOwnership", null);
__decorate([
    Post(':organizationId/leave'),
    HttpCode(HttpStatus.OK),
    UseGuards(OrgRoleGuard),
    __param(0, Param('organizationId')),
    __param(1, Request()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", void 0)
], OrganizationsController.prototype, "leaveOrganization", null);
OrganizationsController = __decorate([
    Controller('organizations'),
    UseGuards(JwtAuthGuard),
    __metadata("design:paramtypes", [OrganizationsService,
        MembershipsService])
], OrganizationsController);
export { OrganizationsController };
//# sourceMappingURL=organizations.controller.js.map