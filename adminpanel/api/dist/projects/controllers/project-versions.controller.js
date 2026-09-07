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
import { Controller, Get, Post, Body, Param, Query, UseGuards, Headers } from '@nestjs/common';
import { ProjectVersionsService } from '../services/project-versions.service.js';
import { CreateProjectVersionDto } from '../validators/layout.validator.js';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { OrgRoleGuard, RequireOrgRole } from '../../auth/guards/org-role.guard.js';
import { MembershipRole } from '@prisma/client';
import { CurrentUser } from '../../auth/decorators/current-user.decorator.js';
import { ThrottlerGuard, Throttle } from '@nestjs/throttler';
let ProjectVersionsController = class ProjectVersionsController {
    projectVersionsService;
    constructor(projectVersionsService) {
        this.projectVersionsService = projectVersionsService;
    }
    async create(user, orgId, projectId, dto, idempotencyKey) {
        return this.projectVersionsService.createVersion(user.id, orgId, projectId, dto, idempotencyKey);
    }
    async restore(user, orgId, projectId, versionId) {
        return this.projectVersionsService.restoreVersion(user.id, orgId, projectId, versionId);
    }
    async findAll(orgId, projectId, page = '1', limit = '25') {
        const pageNum = Math.max(1, parseInt(page, 10) || 1);
        const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10) || 25));
        return this.projectVersionsService.findHistory(orgId, projectId, pageNum, limitNum);
    }
    async findOne(orgId, projectId, versionId) {
        return this.projectVersionsService.findOne(orgId, projectId, versionId);
    }
};
__decorate([
    Post(),
    RequireOrgRole(MembershipRole.OWNER, MembershipRole.EDITOR),
    Throttle({ versions: { limit: 20, ttl: 60000 } }),
    __param(0, CurrentUser()),
    __param(1, Param('orgId')),
    __param(2, Param('projectId')),
    __param(3, Body()),
    __param(4, Headers('idempotency-key')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String, CreateProjectVersionDto, String]),
    __metadata("design:returntype", Promise)
], ProjectVersionsController.prototype, "create", null);
__decorate([
    Post(':versionId/restore'),
    RequireOrgRole(MembershipRole.OWNER, MembershipRole.EDITOR),
    __param(0, CurrentUser()),
    __param(1, Param('orgId')),
    __param(2, Param('projectId')),
    __param(3, Param('versionId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String, String]),
    __metadata("design:returntype", Promise)
], ProjectVersionsController.prototype, "restore", null);
__decorate([
    Get(),
    RequireOrgRole(MembershipRole.OWNER, MembershipRole.EDITOR, MembershipRole.VIEWER),
    __param(0, Param('orgId')),
    __param(1, Param('projectId')),
    __param(2, Query('page')),
    __param(3, Query('limit')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, String]),
    __metadata("design:returntype", Promise)
], ProjectVersionsController.prototype, "findAll", null);
__decorate([
    Get(':versionId'),
    RequireOrgRole(MembershipRole.OWNER, MembershipRole.EDITOR, MembershipRole.VIEWER),
    __param(0, Param('orgId')),
    __param(1, Param('projectId')),
    __param(2, Param('versionId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String]),
    __metadata("design:returntype", Promise)
], ProjectVersionsController.prototype, "findOne", null);
ProjectVersionsController = __decorate([
    Controller('organizations/:orgId/projects/:projectId/versions'),
    UseGuards(JwtAuthGuard, OrgRoleGuard, ThrottlerGuard),
    __metadata("design:paramtypes", [ProjectVersionsService])
], ProjectVersionsController);
export { ProjectVersionsController };
//# sourceMappingURL=project-versions.controller.js.map