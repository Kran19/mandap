import { Controller, Get, Param, Patch, Delete, Body, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { AdminPermissionGuard, RequireAdminPermission } from '../../auth/guards/admin-permission.guard.js';
import { AdminPermissions } from '../constants/admin-permissions.js';
import { AdminUsersService } from '../services/admin-users.service.js';
import { AdminUserQueryDto, AdminUpdateUserDto } from '../dto/admin-users.dto.js';
import { CurrentUser } from '../../auth/decorators/current-user.decorator.js';

@Controller('admin/users')
@UseGuards(JwtAuthGuard, AdminPermissionGuard)
export class AdminUsersController {
  constructor(private readonly usersService: AdminUsersService) {}

  @Get()
  @RequireAdminPermission(AdminPermissions.USERS_READ)
  async findAll(@Query() query: AdminUserQueryDto) {
    return this.usersService.findAll(query);
  }

  @Get(':id')
  @RequireAdminPermission(AdminPermissions.USERS_READ)
  async findOne(@Param('id') id: string) {
    return this.usersService.findOne(id);
  }

  @Patch(':id')
  @RequireAdminPermission(AdminPermissions.USERS_WRITE)
  async updateUser(
    @CurrentUser() actor: any,
    @Param('id') id: string,
    @Body() dto: AdminUpdateUserDto,
  ) {
    return this.usersService.updateUser(actor.id, id, dto);
  }

  @Delete(':id')
  @RequireAdminPermission(AdminPermissions.USERS_WRITE)
  async deleteUser(
    @CurrentUser() actor: any,
    @Param('id') id: string,
  ) {
    return this.usersService.deleteUser(actor.id, id);
  }
}

