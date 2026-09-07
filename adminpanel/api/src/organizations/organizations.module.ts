import { Module } from '@nestjs/common';
import { OrganizationsController } from './organizations.controller.js';
import { OrganizationsService } from './organizations.service.js';
import { MembershipsService } from './memberships.service.js';
import { AuthModule } from '../auth/auth.module.js';
import { PrismaModule } from '../prisma.module.js';

@Module({
  imports: [AuthModule, PrismaModule],
  controllers: [OrganizationsController],
  providers: [OrganizationsService, MembershipsService],
})
export class OrganizationsModule {}
