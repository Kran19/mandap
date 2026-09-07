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
import { AdminAuditLogsService } from '../services/admin-audit-logs.service.js';
import { AdminAuditLogQueryDto } from '../dto/admin-audit-logs.dto.js';
let AdminAuditLogsController = class AdminAuditLogsController {
    auditLogsService;
    constructor(auditLogsService) {
        this.auditLogsService = auditLogsService;
    }
    async findAll(query) {
        return this.auditLogsService.findAll(query);
    }
    async findOne(id) {
        return this.auditLogsService.findOne(id);
    }
};
__decorate([
    Get(),
    RequireAdminPermission(AdminPermissions.AUDIT_LOGS_READ),
    __param(0, Query()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [AdminAuditLogQueryDto]),
    __metadata("design:returntype", Promise)
], AdminAuditLogsController.prototype, "findAll", null);
__decorate([
    Get(':id'),
    RequireAdminPermission(AdminPermissions.AUDIT_LOGS_READ),
    __param(0, Param('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AdminAuditLogsController.prototype, "findOne", null);
AdminAuditLogsController = __decorate([
    Controller('admin/audit-logs'),
    UseGuards(JwtAuthGuard, AdminPermissionGuard),
    __metadata("design:paramtypes", [AdminAuditLogsService])
], AdminAuditLogsController);
export { AdminAuditLogsController };
//# sourceMappingURL=admin-audit-logs.controller.js.map