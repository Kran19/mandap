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
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { AdminPermissionGuard, RequireAdminPermission } from '../../auth/guards/admin-permission.guard.js';
import { AdminPermissions } from '../constants/admin-permissions.js';
import { AdminFeatureFlagsService } from '../services/admin-feature-flags.service.js';
import { AdminFeatureFlagQueryDto, AdminCreateFeatureFlagDto, AdminUpdateFeatureFlagDto } from '../dto/admin-feature-flags.dto.js';
import { CurrentUser } from '../../auth/decorators/current-user.decorator.js';
let AdminFeatureFlagsController = class AdminFeatureFlagsController {
    featureFlagsService;
    constructor(featureFlagsService) {
        this.featureFlagsService = featureFlagsService;
    }
    findAll(actor, query) {
        return this.featureFlagsService.findAll(actor.id, query);
    }
    findOne(actor, id) {
        return this.featureFlagsService.findOne(actor.id, id);
    }
    createFeatureFlag(actor, dto) {
        return this.featureFlagsService.createFeatureFlag(actor.id, dto);
    }
    updateFeatureFlag(actor, id, dto) {
        return this.featureFlagsService.updateFeatureFlag(actor.id, id, dto);
    }
};
__decorate([
    Get(),
    RequireAdminPermission(AdminPermissions.FEATURE_FLAGS_READ),
    __param(0, CurrentUser()),
    __param(1, Query()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, AdminFeatureFlagQueryDto]),
    __metadata("design:returntype", void 0)
], AdminFeatureFlagsController.prototype, "findAll", null);
__decorate([
    Get(':id'),
    RequireAdminPermission(AdminPermissions.FEATURE_FLAGS_READ),
    __param(0, CurrentUser()),
    __param(1, Param('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], AdminFeatureFlagsController.prototype, "findOne", null);
__decorate([
    Post(),
    RequireAdminPermission(AdminPermissions.FEATURE_FLAGS_WRITE),
    __param(0, CurrentUser()),
    __param(1, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, AdminCreateFeatureFlagDto]),
    __metadata("design:returntype", void 0)
], AdminFeatureFlagsController.prototype, "createFeatureFlag", null);
__decorate([
    Patch(':id'),
    RequireAdminPermission(AdminPermissions.FEATURE_FLAGS_WRITE),
    __param(0, CurrentUser()),
    __param(1, Param('id')),
    __param(2, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, AdminUpdateFeatureFlagDto]),
    __metadata("design:returntype", void 0)
], AdminFeatureFlagsController.prototype, "updateFeatureFlag", null);
AdminFeatureFlagsController = __decorate([
    Controller('admin/feature-flags'),
    UseGuards(JwtAuthGuard, AdminPermissionGuard),
    __metadata("design:paramtypes", [AdminFeatureFlagsService])
], AdminFeatureFlagsController);
export { AdminFeatureFlagsController };
//# sourceMappingURL=admin-feature-flags.controller.js.map