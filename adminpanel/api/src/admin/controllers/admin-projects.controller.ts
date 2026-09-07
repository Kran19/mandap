import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { AdminPermissionGuard, RequireAdminPermission } from '../../auth/guards/admin-permission.guard.js';
import { AdminPermissions } from '../constants/admin-permissions.js';
import { AdminProjectsService } from '../services/admin-projects.service.js';
import { AdminProjectQueryDto } from '../dto/admin-projects.dto.js';
import { CurrentUser } from '../../auth/decorators/current-user.decorator.js';

@Controller('admin/projects')
@UseGuards(JwtAuthGuard, AdminPermissionGuard)
export class AdminProjectsController {
  constructor(private readonly projectsService: AdminProjectsService) {}

  @Get()
  @RequireAdminPermission(AdminPermissions.PROJECTS_READ)
  findAll(@CurrentUser() actor: any, @Query() query: AdminProjectQueryDto) {
    return this.projectsService.findAll(actor.id, query);
  }

  @Get(':id')
  @RequireAdminPermission(AdminPermissions.PROJECTS_READ)
  findOne(@CurrentUser() actor: any, @Param('id') id: string) {
    return this.projectsService.findOne(actor.id, id);
  }

  @Get(':id/versions/:versionId')
  @RequireAdminPermission(AdminPermissions.PROJECTS_READ)
  findVersion(@CurrentUser() actor: any, @Param('id') id: string, @Param('versionId') versionId: string) {
    return this.projectsService.findVersion(actor.id, id, versionId);
  }
}
