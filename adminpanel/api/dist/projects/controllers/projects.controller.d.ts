import { ProjectsService, CreateProjectDto, UpdateProjectDto } from '../services/projects.service.js';
export declare class ProjectsController {
    private readonly projectsService;
    constructor(projectsService: ProjectsService);
    create(user: any, orgId: string, dto: Omit<CreateProjectDto, 'organizationId'>): Promise<{
        id: string;
        status: import("@prisma/client").$Enums.ProjectStatus;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        organizationId: string;
        description: string | null;
        currentVersionId: string | null;
        createdBy: string | null;
        archivedAt: Date | null;
    }>;
    findAll(orgId: string, page?: string, limit?: string): Promise<{
        data: {
            id: string;
            status: import("@prisma/client").$Enums.ProjectStatus;
            createdAt: Date;
            updatedAt: Date;
            name: string;
            organizationId: string;
            description: string | null;
            currentVersionId: string | null;
            createdBy: string | null;
            archivedAt: Date | null;
        }[];
        meta: {
            total: number;
            page: number;
            limit: number;
        };
    }>;
    findOne(orgId: string, projectId: string): Promise<{
        id: string;
        status: import("@prisma/client").$Enums.ProjectStatus;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        organizationId: string;
        description: string | null;
        currentVersionId: string | null;
        createdBy: string | null;
        archivedAt: Date | null;
    }>;
    update(user: any, orgId: string, projectId: string, dto: UpdateProjectDto): Promise<{
        id: string;
        status: import("@prisma/client").$Enums.ProjectStatus;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        organizationId: string;
        description: string | null;
        currentVersionId: string | null;
        createdBy: string | null;
        archivedAt: Date | null;
    }>;
    archive(user: any, orgId: string, projectId: string): Promise<{
        id: string;
        status: import("@prisma/client").$Enums.ProjectStatus;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        organizationId: string;
        description: string | null;
        currentVersionId: string | null;
        createdBy: string | null;
        archivedAt: Date | null;
    }>;
    restore(user: any, orgId: string, projectId: string): Promise<{
        id: string;
        status: import("@prisma/client").$Enums.ProjectStatus;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        organizationId: string;
        description: string | null;
        currentVersionId: string | null;
        createdBy: string | null;
        archivedAt: Date | null;
    }>;
    remove(user: any, orgId: string, projectId: string): Promise<{
        id: string;
        status: import("@prisma/client").$Enums.ProjectStatus;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        organizationId: string;
        description: string | null;
        currentVersionId: string | null;
        createdBy: string | null;
        archivedAt: Date | null;
    }>;
}
