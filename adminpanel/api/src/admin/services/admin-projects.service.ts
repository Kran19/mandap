import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
import { AdminProjectQueryDto } from '../dto/admin-projects.dto.js';

@Injectable()
export class AdminProjectsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(actorId: string, query: AdminProjectQueryDto) {
    const { page, limit, search, status, organizationId, skip } = query;

    const where: any = {};
    if (status) where.status = status;
    if (organizationId) where.organizationId = organizationId;
    if (search) {
      where.name = { contains: search, mode: 'insensitive' };
    }

    const [data, total] = await Promise.all([
      this.prisma.project.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          organization: { select: { id: true, name: true, slug: true } },
          _count: { select: { versions: true } },
        },
      }),
      this.prisma.project.count({ where }),
    ]);

    return {
      data,
      meta: { total, page, limit },
    };
  }

  async findOne(actorId: string, projectId: string) {
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      include: {
        organization: { select: { id: true, name: true, slug: true } },
        versions: {
          orderBy: { versionNumber: 'desc' },
          take: 10,
        },
        _count: { select: { versions: true } },
      },
    });

    if (!project) throw new NotFoundException('Project not found');
    return project;
  }

  async findVersion(actorId: string, projectId: string, versionId: string) {
    const version = await this.prisma.projectVersion.findUnique({
      where: { id: versionId, projectId },
    });
    if (!version) throw new NotFoundException('Version not found');
    return version;
  }
}
