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
import { AdminProjectsService } from '../services/admin-projects.service.js';
import { AdminProjectQueryDto } from '../dto/admin-projects.dto.js';
import { CurrentUser } from '../../auth/decorators/current-user.decorator.js';
let AdminProjectsController = class AdminProjectsController {
    projectsService;
    constructor(projectsService) {
        this.projectsService = projectsService;
    }
    findAll(actor, query) {
        return this.projectsService.findAll(actor.id, query);
    }
    findOne(actor, id) {
        return this.projectsService.findOne(actor.id, id);
    }
    findVersion(actor, id, versionId) {
        return this.projectsService.findVersion(actor.id, id, versionId);
    }
};
__decorate([
    Get(),
    RequireAdminPermission(AdminPermissions.PROJECTS_READ),
    __param(0, CurrentUser()),
    __param(1, Query()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, AdminProjectQueryDto]),
    __metadata("design:returntype", void 0)
], AdminProjectsController.prototype, "findAll", null);
__decorate([
    Get(':id'),
    RequireAdminPermission(AdminPermissions.PROJECTS_READ),
    __param(0, CurrentUser()),
    __param(1, Param('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], AdminProjectsController.prototype, "findOne", null);
__decorate([
    Get(':id/versions/:versionId'),
    RequireAdminPermission(AdminPermissions.PROJECTS_READ),
    __param(0, CurrentUser()),
    __param(1, Param('id')),
    __param(2, Param('versionId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", void 0)
], AdminProjectsController.prototype, "findVersion", null);
AdminProjectsController = __decorate([
    Controller('admin/projects'),
    UseGuards(JwtAuthGuard, AdminPermissionGuard),
    __metadata("design:paramtypes", [AdminProjectsService])
], AdminProjectsController);
export { AdminProjectsController };
//# sourceMappingURL=admin-projects.controller.js.map