import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard.js';
import { OrgRoleGuard, RequireOrgRole } from '../../auth/guards/org-role.guard.js';
import { MembershipRole } from '@prisma/client';
import { EntitlementService } from '../services/entitlement.service.js';

@Controller('billing/entitlement')
@UseGuards(JwtAuthGuard)
export class EntitlementController {
  constructor(private readonly entitlementService: EntitlementService) {}

  @Get(':organizationId')
  @UseGuards(OrgRoleGuard)
  @RequireOrgRole(MembershipRole.VIEWER)
  async getEntitlement(@Param('organizationId') organizationId: string) {
    return this.entitlementService.getApplicationAccess(organizationId);
  }
}
