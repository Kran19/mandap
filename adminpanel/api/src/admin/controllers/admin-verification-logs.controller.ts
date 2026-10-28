import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { AdminPermissionGuard, RequireAdminPermission } from '../../auth/guards/admin-permission.guard.js';
import { AdminPermissions } from '../constants/admin-permissions.js';
import { AdminVerificationLogsService } from '../services/admin-verification-logs.service.js';
import { AdminVerificationLogQueryDto } from '../dto/admin-verification-logs.dto.js';

@Controller('admin/verification-logs')
@UseGuards(JwtAuthGuard, AdminPermissionGuard)
export class AdminVerificationLogsController {
  constructor(private readonly verificationLogsService: AdminVerificationLogsService) {}

  @Get()
  @RequireAdminPermission(AdminPermissions.USERS_READ)
  async findAll(@Query() query: AdminVerificationLogQueryDto) {
    return this.verificationLogsService.findAll(query);
  }

  @Get(':id')
  @RequireAdminPermission(AdminPermissions.USERS_READ)
  async findOne(@Param('id') id: string) {
    return this.verificationLogsService.findOne(id);
  }
}
