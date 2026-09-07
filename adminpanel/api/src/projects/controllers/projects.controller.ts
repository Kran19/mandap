import { Controller, Get, Post, Patch, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ProjectsService, CreateProjectDto, UpdateProjectDto } from '../services/projects.service.js';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { OrgRoleGuard, RequireOrgRole } from '../../auth/guards/org-role.guard.js';
import { MembershipRole } from '@prisma/client';
import { CurrentUser } from '../../auth/decorators/current-user.decorator.js';

@Controller('organizations/:orgId/projects')
@UseGuards(JwtAuthGuard, OrgRoleGuard)
export class ProjectsController {
  constructor(private readonly projectsService: ProjectsService) {}

  @Post()
  @RequireOrgRole(MembershipRole.OWNER, MembershipRole.EDITOR)
  async create(
    @CurrentUser() user: any,
    @Param('orgId') orgId: string,
    @Body() dto: Omit<CreateProjectDto, 'organizationId'>,
  ) {
    return this.projectsService.create(user.id, orgId, { ...dto, organizationId: orgId });
  }

  @Get()
  @RequireOrgRole(MembershipRole.OWNER, MembershipRole.EDITOR, MembershipRole.VIEWER)
  async findAll(
    @Param('orgId') orgId: string,
    @Query('page') page: string = '1',
    @Query('limit') limit: string = '25',
  ) {
    const pageNum = Math.max(1, parseInt(page, 10) || 1);
    const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10) || 25));
    return this.projectsService.findAll(orgId, pageNum, limitNum);
  }

  @Get(':projectId')
  @RequireOrgRole(MembershipRole.OWNER, MembershipRole.EDITOR, MembershipRole.VIEWER)
  async findOne(@Param('orgId') orgId: string, @Param('projectId') projectId: string) {
    return this.projectsService.findOne(orgId, projectId);
  }

  @Patch(':projectId')
  @RequireOrgRole(MembershipRole.OWNER, MembershipRole.EDITOR)
  async update(
    @CurrentUser() user: any,
    @Param('orgId') orgId: string,
    @Param('projectId') projectId: string,
    @Body() dto: UpdateProjectDto,
  ) {
    return this.projectsService.update(user.id, orgId, projectId, dto);
  }

  @Post(':projectId/archive')
  @RequireOrgRole(MembershipRole.OWNER)
  async archive(
    @CurrentUser() user: any,
    @Param('orgId') orgId: string,
    @Param('projectId') projectId: string,
  ) {
    return this.projectsService.archive(user.id, orgId, projectId);
  }

  @Post(':projectId/restore')
  @RequireOrgRole(MembershipRole.OWNER)
  async restore(
    @CurrentUser() user: any,
    @Param('orgId') orgId: string,
    @Param('projectId') projectId: string,
  ) {
    return this.projectsService.restore(user.id, orgId, projectId);
  }

  @Delete(':projectId')
  @RequireOrgRole(MembershipRole.OWNER)
  async remove(
    @CurrentUser() user: any,
    @Param('orgId') orgId: string,
    @Param('projectId') projectId: string,
  ) {
    return this.projectsService.remove(user.id, orgId, projectId);
  }
}
