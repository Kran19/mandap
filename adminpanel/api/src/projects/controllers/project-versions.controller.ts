import { Controller, Get, Post, Body, Param, Query, UseGuards, Headers } from '@nestjs/common';
import { ProjectVersionsService } from '../services/project-versions.service.js';
import { CreateProjectVersionDto } from '../validators/layout.validator.js';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { OrgRoleGuard, RequireOrgRole } from '../../auth/guards/org-role.guard.js';
import { MembershipRole } from '@prisma/client';
import { CurrentUser } from '../../auth/decorators/current-user.decorator.js';
import { ThrottlerGuard, Throttle } from '@nestjs/throttler';

@Controller('organizations/:orgId/projects/:projectId/versions')
@UseGuards(JwtAuthGuard, OrgRoleGuard, ThrottlerGuard)
export class ProjectVersionsController {
  constructor(private readonly projectVersionsService: ProjectVersionsService) {}

  @Post()
  @RequireOrgRole(MembershipRole.OWNER, MembershipRole.EDITOR)
  @Throttle({ versions: { limit: 20, ttl: 60000 } })
  async create(
    @CurrentUser() user: any,
    @Param('orgId') orgId: string,
    @Param('projectId') projectId: string,
    @Body() dto: CreateProjectVersionDto,
    @Headers('idempotency-key') idempotencyKey?: string,
  ) {
    return this.projectVersionsService.createVersion(user.id, orgId, projectId, dto, idempotencyKey);
  }

  @Post(':versionId/restore')
  @RequireOrgRole(MembershipRole.OWNER, MembershipRole.EDITOR)
  async restore(
    @CurrentUser() user: any,
    @Param('orgId') orgId: string,
    @Param('projectId') projectId: string,
    @Param('versionId') versionId: string,
  ) {
    return this.projectVersionsService.restoreVersion(user.id, orgId, projectId, versionId);
  }

  @Get()
  @RequireOrgRole(MembershipRole.OWNER, MembershipRole.EDITOR, MembershipRole.VIEWER)
  async findAll(
    @Param('orgId') orgId: string,
    @Param('projectId') projectId: string,
    @Query('page') page: string = '1',
    @Query('limit') limit: string = '25',
  ) {
    const pageNum = Math.max(1, parseInt(page, 10) || 1);
    const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10) || 25));
    return this.projectVersionsService.findHistory(orgId, projectId, pageNum, limitNum);
  }

  @Get(':versionId')
  @RequireOrgRole(MembershipRole.OWNER, MembershipRole.EDITOR, MembershipRole.VIEWER)
  async findOne(
    @Param('orgId') orgId: string,
    @Param('projectId') projectId: string,
    @Param('versionId') versionId: string,
  ) {
    return this.projectVersionsService.findOne(orgId, projectId, versionId);
  }
}
