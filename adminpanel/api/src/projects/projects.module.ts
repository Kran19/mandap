import { Module } from '@nestjs/common';
import { ProjectsController } from './controllers/projects.controller.js';
import { ProjectVersionsController } from './controllers/project-versions.controller.js';
import { ProjectsService } from './services/projects.service.js';
import { ProjectVersionsService } from './services/project-versions.service.js';
import { PrismaModule } from '../prisma.module.js';
import { OrganizationsModule } from '../organizations/organizations.module.js';
import { BillingModule } from '../billing/billing.module.js';
import { AdminModule } from '../admin/admin.module.js';

@Module({
  imports: [PrismaModule, OrganizationsModule, BillingModule, AdminModule],
  controllers: [ProjectsController, ProjectVersionsController],
  providers: [ProjectsService, ProjectVersionsService],
  exports: [ProjectsService, ProjectVersionsService],
})
export class ProjectsModule {}
