import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards, Request, HttpCode, HttpStatus } from '@nestjs/common';
import { OrganizationsService } from './organizations.service.js';
import { MembershipsService } from './memberships.service.js';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { OrgRoleGuard, RequireOrgRole } from '../auth/guards/org-role.guard.js';
import { CreateOrganizationDto } from './dto/create-organization.dto.js';
import { UpdateOrganizationDto } from './dto/update-organization.dto.js';
import { AddMemberDto } from './dto/add-member.dto.js';
import { UpdateMemberRoleDto } from './dto/update-member-role.dto.js';
import { TransferOwnershipDto } from './dto/transfer-ownership.dto.js';
import { MembershipRole } from '@prisma/client';

@Controller('organizations')
@UseGuards(JwtAuthGuard)
export class OrganizationsController {
  constructor(
    private readonly organizationsService: OrganizationsService,
    private readonly membershipsService: MembershipsService,
  ) {}

  // -----------------------------------------------------
  // Organizations
  // -----------------------------------------------------

  @Post()
  create(@Request() req: any, @Body() dto: CreateOrganizationDto) {
    return this.organizationsService.createOrganization(req.user.id, dto);
  }

  @Get()
  findAll(@Request() req: any) {
    return this.organizationsService.getUserOrganizations(req.user.id);
  }

  @Get(':organizationId')
  @UseGuards(OrgRoleGuard)
  // ANY member can view (OWNER, EDITOR, VIEWER) - if omitted or empty, it defaults to checking membership existence
  findOne(@Param('organizationId') organizationId: string) {
    return this.organizationsService.getOrganization(organizationId);
  }

  @Patch(':organizationId')
  @UseGuards(OrgRoleGuard)
  @RequireOrgRole(MembershipRole.OWNER)
  update(@Param('organizationId') organizationId: string, @Body() dto: UpdateOrganizationDto) {
    return this.organizationsService.updateOrganization(organizationId, dto);
  }

  // -----------------------------------------------------
  // Memberships
  // -----------------------------------------------------

  @Get(':organizationId/members')
  @UseGuards(OrgRoleGuard)
  // ANY member can view
  getMembers(@Param('organizationId') organizationId: string) {
    return this.membershipsService.getMembers(organizationId);
  }

  @Post(':organizationId/members')
  @UseGuards(OrgRoleGuard)
  @RequireOrgRole(MembershipRole.OWNER)
  addMember(@Param('organizationId') organizationId: string, @Body() dto: AddMemberDto) {
    return this.membershipsService.addMember(organizationId, dto);
  }

  @Patch(':organizationId/members/:userId')
  @UseGuards(OrgRoleGuard)
  @RequireOrgRole(MembershipRole.OWNER)
  updateMemberRole(
    @Param('organizationId') organizationId: string,
    @Param('userId') targetUserId: string,
    @Body() dto: UpdateMemberRoleDto,
  ) {
    return this.membershipsService.updateMemberRole(organizationId, targetUserId, dto);
  }

  @Delete(':organizationId/members/:userId')
  @UseGuards(OrgRoleGuard)
  @RequireOrgRole(MembershipRole.OWNER)
  removeMember(@Param('organizationId') organizationId: string, @Param('userId') targetUserId: string) {
    return this.membershipsService.removeMember(organizationId, targetUserId);
  }

  @Post(':organizationId/ownership-transfer')
  @HttpCode(HttpStatus.OK)
  @UseGuards(OrgRoleGuard)
  @RequireOrgRole(MembershipRole.OWNER)
  transferOwnership(
    @Param('organizationId') organizationId: string,
    @Request() req: any,
    @Body() dto: TransferOwnershipDto,
  ) {
    return this.membershipsService.transferOwnership(organizationId, req.user.id, dto.newOwnerId);
  }

  @Post(':organizationId/leave')
  @HttpCode(HttpStatus.OK)
  @UseGuards(OrgRoleGuard)
  leaveOrganization(@Param('organizationId') organizationId: string, @Request() req: any) {
    return this.membershipsService.leaveOrganization(organizationId, req.user.id);
  }
}
