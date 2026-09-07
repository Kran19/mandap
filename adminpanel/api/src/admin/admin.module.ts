import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { PrismaModule } from '../prisma.module.js';
import { BillingModule } from '../billing/billing.module.js';

import { AdminAuditService } from './services/admin-audit.service.js';
import { AdminUsersService } from './services/admin-users.service.js';
import { AdminOrganizationsService } from './services/admin-organizations.service.js';
import { AdminMembershipsService } from './services/admin-memberships.service.js';
import { AdminRolesService } from './services/admin-roles.service.js';
import { AdminPlansService } from './services/admin-plans.service.js';
import { AdminProjectsService } from './services/admin-projects.service.js';
import { AdminFeatureFlagsService } from './services/admin-feature-flags.service.js';
import { AdminUsageService } from './services/admin-usage.service.js';
import { AdminAuditLogsService } from './services/admin-audit-logs.service.js';
import { AdminBillingService } from './services/admin-billing.service.js';

import { AdminUsersController } from './controllers/admin-users.controller.js';
import { AdminOrganizationsController } from './controllers/admin-organizations.controller.js';
import { AdminMembershipsController } from './controllers/admin-memberships.controller.js';
import { AdminRolesController } from './controllers/admin-roles.controller.js';
import { AdminPermissionsController } from './controllers/admin-permissions.controller.js';
import { AdminPlansController } from './controllers/admin-plans.controller.js';
import { AdminProjectsController } from './controllers/admin-projects.controller.js';
import { AdminFeatureFlagsController } from './controllers/admin-feature-flags.controller.js';
import { AdminUsageController } from './controllers/admin-usage.controller.js';
import { AdminAuditLogsController } from './controllers/admin-audit-logs.controller.js';
import { AdminController } from './controllers/admin.controller.js';
import { AdminBillingController } from './controllers/admin-billing.controller.js';

@Module({
  imports: [AuthModule, PrismaModule, BillingModule],
  controllers: [
    AdminUsersController,
    AdminOrganizationsController,
    AdminMembershipsController,
    AdminRolesController,
    AdminPermissionsController,
    AdminPlansController,
    AdminProjectsController,
    AdminFeatureFlagsController,
    AdminUsageController,
    AdminAuditLogsController,
    AdminController,
    AdminBillingController,
  ],
  providers: [
    AdminAuditService,
    AdminUsersService,
    AdminOrganizationsService,
    AdminMembershipsService,
    AdminRolesService,
    AdminPlansService,
    AdminProjectsService,
    AdminFeatureFlagsService,
    AdminUsageService,
    AdminAuditLogsService,
    AdminBillingService,
  ]
})
export class AdminModule {}
