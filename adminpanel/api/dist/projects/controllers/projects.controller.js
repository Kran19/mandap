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
import { Controller, Get, Post, Patch, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ProjectsService, UpdateProjectDto } from '../services/projects.service.js';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { OrgRoleGuard, RequireOrgRole } from '../../auth/guards/org-role.guard.js';
import { MembershipRole } from '@prisma/client';
import { CurrentUser } from '../../auth/decorators/current-user.decorator.js';
let ProjectsController = class ProjectsController {
    projectsService;
    constructor(projectsService) {
        this.projectsService = projectsService;
    }
    async create(user, orgId, dto) {
        return this.projectsService.create(user.id, orgId, { ...dto, organizationId: orgId });
    }
    async findAll(orgId, page = '1', limit = '25') {
        const pageNum = Math.max(1, parseInt(page, 10) || 1);
        const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10) || 25));
        return this.projectsService.findAll(orgId, pageNum, limitNum);
    }
    async findOne(orgId, projectId) {
        return this.projectsService.findOne(orgId, projectId);
    }
    async update(user, orgId, projectId, dto) {
        return this.projectsService.update(user.id, orgId, projectId, dto);
    }
    async archive(user, orgId, projectId) {
        return this.projectsService.archive(user.id, orgId, projectId);
    }
    async restore(user, orgId, projectId) {
        return this.projectsService.restore(user.id, orgId, projectId);
    }
    async remove(user, orgId, projectId) {
        return this.projectsService.remove(user.id, orgId, projectId);
    }
};
__decorate([
    Post(),
    RequireOrgRole(MembershipRole.OWNER, MembershipRole.EDITOR),
    __param(0, CurrentUser()),
    __param(1, Param('orgId')),
    __param(2, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], ProjectsController.prototype, "create", null);
__decorate([
    Get(),
    RequireOrgRole(MembershipRole.OWNER, MembershipRole.EDITOR, MembershipRole.VIEWER),
    __param(0, Param('orgId')),
    __param(1, Query('page')),
    __param(2, Query('limit')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String]),
    __metadata("design:returntype", Promise)
], ProjectsController.prototype, "findAll", null);
__decorate([
    Get(':projectId'),
    RequireOrgRole(MembershipRole.OWNER, MembershipRole.EDITOR, MembershipRole.VIEWER),
    __param(0, Param('orgId')),
    __param(1, Param('projectId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", Promise)
], ProjectsController.prototype, "findOne", null);
__decorate([
    Patch(':projectId'),
    RequireOrgRole(MembershipRole.OWNER, MembershipRole.EDITOR),
    __param(0, CurrentUser()),
    __param(1, Param('orgId')),
    __param(2, Param('projectId')),
    __param(3, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String, UpdateProjectDto]),
    __metadata("design:returntype", Promise)
], ProjectsController.prototype, "update", null);
__decorate([
    Post(':projectId/archive'),
    RequireOrgRole(MembershipRole.OWNER),
    __param(0, CurrentUser()),
    __param(1, Param('orgId')),
    __param(2, Param('projectId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", Promise)
], ProjectsController.prototype, "archive", null);
__decorate([
    Post(':projectId/restore'),
    RequireOrgRole(MembershipRole.OWNER),
    __param(0, CurrentUser()),
    __param(1, Param('orgId')),
    __param(2, Param('projectId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", Promise)
], ProjectsController.prototype, "restore", null);
__decorate([
    Delete(':projectId'),
    RequireOrgRole(MembershipRole.OWNER),
    __param(0, CurrentUser()),
    __param(1, Param('orgId')),
    __param(2, Param('projectId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", Promise)
], ProjectsController.prototype, "remove", null);
ProjectsController = __decorate([
    Controller('organizations/:orgId/projects'),
    UseGuards(JwtAuthGuard, OrgRoleGuard),
    __metadata("design:paramtypes", [ProjectsService])
], ProjectsController);
export { ProjectsController };
//# sourceMappingURL=projects.controller.js.map