import { Controller, Get, Post, Patch, Param, Body, Query, UseGuards } from '@nestjs/common';
import { AdminRolesService } from '../services/admin-roles.service.js';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { AdminPermissionGuard, RequireAdminPermission } from '../../auth/guards/admin-permission.guard.js';
import { AdminPermissions } from '../constants/admin-permissions.js';
import { AdminRoleQueryDto, AdminCreateRoleDto, AdminUpdateRoleDto } from '../dto/admin-roles.dto.js';
import { CurrentUser } from '../../auth/decorators/current-user.decorator.js';

@Controller('admin/roles')
@UseGuards(JwtAuthGuard, AdminPermissionGuard)
export class AdminRolesController {
  constructor(private readonly adminRolesService: AdminRolesService) {}

  @Get()
  @RequireAdminPermission(AdminPermissions.ROLES_READ)
  findAll(@CurrentUser() user: any, @Query() query: AdminRoleQueryDto) {
    return this.adminRolesService.findAll(user.id, query);
  }

  @Get(':id')
  @RequireAdminPermission(AdminPermissions.ROLES_READ)
  findOne(@CurrentUser() user: any, @Param('id') id: string) {
    return this.adminRolesService.findOne(user.id, id);
  }

  @Post()
  @RequireAdminPermission(AdminPermissions.ROLES_WRITE)
  createRole(@CurrentUser() user: any, @Body() dto: AdminCreateRoleDto) {
    return this.adminRolesService.createRole(user.id, dto);
  }

  @Patch(':id')
  @RequireAdminPermission(AdminPermissions.ROLES_WRITE)
  updateRole(@CurrentUser() user: any, @Param('id') id: string, @Body() dto: AdminUpdateRoleDto) {
    return this.adminRolesService.updateRole(user.id, id, dto);
  }

  // Preserve the explicit super-admin promotion endpoints (Phase 4 requirement)
  @Post('grant-super-admin/:userId')
  @RequireAdminPermission(AdminPermissions.ROLES_WRITE)
  grantSuperAdmin(@CurrentUser() user: any, @Param('userId') targetUserId: string) {
    return this.adminRolesService.grantSuperAdmin(user.id, targetUserId);
  }

  @Post('revoke-super-admin/:userId')
  @RequireAdminPermission(AdminPermissions.ROLES_WRITE)
  revokeSuperAdmin(@CurrentUser() user: any, @Param('userId') targetUserId: string) {
    return this.adminRolesService.revokeSuperAdmin(user.id, targetUserId);
  }
}
