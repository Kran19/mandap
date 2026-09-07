var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
import { Module } from '@nestjs/common';
import { ProjectsController } from './controllers/projects.controller.js';
import { ProjectVersionsController } from './controllers/project-versions.controller.js';
import { ProjectsService } from './services/projects.service.js';
import { ProjectVersionsService } from './services/project-versions.service.js';
import { PrismaModule } from '../prisma.module.js';
import { OrganizationsModule } from '../organizations/organizations.module.js';
import { BillingModule } from '../billing/billing.module.js';
import { AdminModule } from '../admin/admin.module.js';
let ProjectsModule = class ProjectsModule {
};
ProjectsModule = __decorate([
    Module({
        imports: [PrismaModule, OrganizationsModule, BillingModule, AdminModule],
        controllers: [ProjectsController, ProjectVersionsController],
        providers: [ProjectsService, ProjectVersionsService],
        exports: [ProjectsService, ProjectVersionsService],
    })
], ProjectsModule);
export { ProjectsModule };
//# sourceMappingURL=projects.module.js.map