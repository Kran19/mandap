import { Controller, Get, Post, Patch, Param, Body, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { AdminPermissionGuard, RequireAdminPermission } from '../../auth/guards/admin-permission.guard.js';
import { AdminPermissions } from '../constants/admin-permissions.js';
import { AdminFeatureFlagsService } from '../services/admin-feature-flags.service.js';
import { AdminFeatureFlagQueryDto, AdminCreateFeatureFlagDto, AdminUpdateFeatureFlagDto } from '../dto/admin-feature-flags.dto.js';
import { CurrentUser } from '../../auth/decorators/current-user.decorator.js';

@Controller('admin/feature-flags')
@UseGuards(JwtAuthGuard, AdminPermissionGuard)
export class AdminFeatureFlagsController {
  constructor(private readonly featureFlagsService: AdminFeatureFlagsService) {}

  @Get()
  @RequireAdminPermission(AdminPermissions.FEATURE_FLAGS_READ)
  findAll(@CurrentUser() actor: any, @Query() query: AdminFeatureFlagQueryDto) {
    return this.featureFlagsService.findAll(actor.id, query);
  }

  @Get(':id')
  @RequireAdminPermission(AdminPermissions.FEATURE_FLAGS_READ)
  findOne(@CurrentUser() actor: any, @Param('id') id: string) {
    return this.featureFlagsService.findOne(actor.id, id);
  }

  @Post()
  @RequireAdminPermission(AdminPermissions.FEATURE_FLAGS_WRITE)
  createFeatureFlag(@CurrentUser() actor: any, @Body() dto: AdminCreateFeatureFlagDto) {
    return this.featureFlagsService.createFeatureFlag(actor.id, dto);
  }

  @Patch(':id')
  @RequireAdminPermission(AdminPermissions.FEATURE_FLAGS_WRITE)
  updateFeatureFlag(@CurrentUser() actor: any, @Param('id') id: string, @Body() dto: AdminUpdateFeatureFlagDto) {
    return this.featureFlagsService.updateFeatureFlag(actor.id, id, dto);
  }
}
