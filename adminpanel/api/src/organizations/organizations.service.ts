import { Injectable, ConflictException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service.js';
import { CreateOrganizationDto } from './dto/create-organization.dto.js';
import { UpdateOrganizationDto } from './dto/update-organization.dto.js';
import { MembershipRole } from '@prisma/client';

@Injectable()
export class OrganizationsService {
  constructor(private prisma: PrismaService) {}

  async createOrganization(userId: string, dto: CreateOrganizationDto) {
    const baseSlug = this.generateSlug(dto.name);
    let currentSlug = baseSlug;
    let counter = 1;

    // Retry loop for slug collision
    while (true) {
      try {
        const result = await this.prisma.$transaction(async (tx) => {
          const org = await tx.organization.create({
            data: {
              name: dto.name,
              slug: currentSlug,
            },
          });

          await tx.organizationMember.create({
            data: {
              organizationId: org.id,
              userId: userId,
              role: MembershipRole.OWNER,
            },
          });

          return org;
        });

        return result;
      } catch (error: any) {
        // If unique constraint failed on slug, retry with appended counter
        if (error.code === 'P2002' && error.meta?.target?.includes('slug')) {
          counter++;
          currentSlug = `${baseSlug}-${counter}`;
          if (counter > 10) {
            throw new ConflictException('Unable to generate a unique organization slug. Please try a different name.');
          }
        } else {
          throw error; // Let the global exception filter handle it
        }
      }
    }
  }

  async getUserOrganizations(userId: string) {
    const memberships = await this.prisma.organizationMember.findMany({
      where: { userId },
      include: {
        organization: true,
      },
    });

    return memberships.map((m) => ({
      id: m.organization.id,
      name: m.organization.name,
      slug: m.organization.slug,
      status: m.organization.status,
      role: m.role,
    }));
  }

  async getOrganization(organizationId: string) {
    const org = await this.prisma.organization.findUnique({
      where: { id: organizationId },
    });

    if (!org) {
      throw new NotFoundException('Organization not found');
    }

    return {
      id: org.id,
      name: org.name,
      slug: org.slug,
      status: org.status,
    };
  }

  async updateOrganization(organizationId: string, dto: UpdateOrganizationDto) {
    const org = await this.prisma.organization.update({
      where: { id: organizationId },
      data: {
        name: dto.name,
      },
    });

    return {
      id: org.id,
      name: org.name,
      slug: org.slug,
      status: org.status,
    };
  }

  private generateSlug(name: string): string {
    return name
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)+/g, '');
  }
}
