import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { AdminPermissionGuard, RequireAdminPermission } from '../../auth/guards/admin-permission.guard.js';
import { AdminPermissions } from '../constants/admin-permissions.js';
import { AdminAuditLogsService } from '../services/admin-audit-logs.service.js';
import { AdminAuditLogQueryDto } from '../dto/admin-audit-logs.dto.js';

@Controller('admin/audit-logs')
@UseGuards(JwtAuthGuard, AdminPermissionGuard)
export class AdminAuditLogsController {
  constructor(private readonly auditLogsService: AdminAuditLogsService) {}

  @Get()
  @RequireAdminPermission(AdminPermissions.AUDIT_LOGS_READ)
  async findAll(@Query() query: AdminAuditLogQueryDto) {
    return this.auditLogsService.findAll(query);
  }

  @Get(':id')
  @RequireAdminPermission(AdminPermissions.AUDIT_LOGS_READ)
  async findOne(@Param('id') id: string) {
    return this.auditLogsService.findOne(id);
  }
}
