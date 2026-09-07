import { Controller, Get, Param, Post, Patch, Delete, Body, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { AdminPermissionGuard, RequireAdminPermission } from '../../auth/guards/admin-permission.guard.js';
import { AdminPermissions } from '../constants/admin-permissions.js';
import { AdminMembershipsService } from '../services/admin-memberships.service.js';
import { AdminMembershipQueryDto, AdminAddMembershipDto, AdminUpdateMembershipDto } from '../dto/admin-memberships.dto.js';
import { CurrentUser } from '../../auth/decorators/current-user.decorator.js';

@Controller('admin/organizations/:orgId/members')
@UseGuards(JwtAuthGuard, AdminPermissionGuard)
export class AdminMembershipsController {
  constructor(private readonly membershipsService: AdminMembershipsService) {}

  @Get()
  @RequireAdminPermission(AdminPermissions.MEMBERSHIPS_READ)
  async findAll(
    @CurrentUser() actor: any,
    @Param('orgId') orgId: string,
    @Query() query: AdminMembershipQueryDto,
  ) {
    return this.membershipsService.findAll(actor.id, orgId, query);
  }

  @Post()
  @RequireAdminPermission(AdminPermissions.MEMBERSHIPS_WRITE)
  async addMember(
    @CurrentUser() actor: any,
    @Param('orgId') orgId: string,
    @Body() dto: AdminAddMembershipDto,
  ) {
    return this.membershipsService.addMember(actor.id, orgId, dto);
  }

  @Patch(':userId')
  @RequireAdminPermission(AdminPermissions.MEMBERSHIPS_WRITE)
  async updateMemberRole(
    @CurrentUser() actor: any,
    @Param('orgId') orgId: string,
    @Param('userId') userId: string,
    @Body() dto: AdminUpdateMembershipDto,
  ) {
    return this.membershipsService.updateMemberRole(actor.id, orgId, userId, dto);
  }

  @Delete(':userId')
  @RequireAdminPermission(AdminPermissions.MEMBERSHIPS_WRITE)
  async removeMember(
    @CurrentUser() actor: any,
    @Param('orgId') orgId: string,
    @Param('userId') userId: string,
  ) {
    return this.membershipsService.removeMember(actor.id, orgId, userId);
  }
}
