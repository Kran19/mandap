import { Controller, Get, Post, Patch, Param, Body, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { AdminPermissionGuard, RequireAdminPermission } from '../../auth/guards/admin-permission.guard.js';
import { AdminPermissions } from '../constants/admin-permissions.js';
import { AdminPlansService } from '../services/admin-plans.service.js';
import { AdminPlanQueryDto, AdminCreatePlanDto, AdminUpdatePlanDto } from '../dto/admin-plans.dto.js';
import { CurrentUser } from '../../auth/decorators/current-user.decorator.js';

@Controller('admin/plans')
@UseGuards(JwtAuthGuard, AdminPermissionGuard)
export class AdminPlansController {
  constructor(private readonly plansService: AdminPlansService) {}

  @Get()
  @RequireAdminPermission(AdminPermissions.PLANS_READ)
  findAll(@CurrentUser() actor: any, @Query() query: AdminPlanQueryDto) {
    return this.plansService.findAll(actor.id, query);
  }

  @Get(':id')
  @RequireAdminPermission(AdminPermissions.PLANS_READ)
  findOne(@CurrentUser() actor: any, @Param('id') id: string) {
    return this.plansService.findOne(actor.id, id);
  }

  @Post()
  @RequireAdminPermission(AdminPermissions.PLANS_WRITE)
  createPlan(@CurrentUser() actor: any, @Body() dto: AdminCreatePlanDto) {
    return this.plansService.createPlan(actor.id, dto);
  }

  @Patch(':id')
  @RequireAdminPermission(AdminPermissions.PLANS_WRITE)
  updatePlan(@CurrentUser() actor: any, @Param('id') id: string, @Body() dto: AdminUpdatePlanDto) {
    return this.plansService.updatePlan(actor.id, id, dto);
  }
}
