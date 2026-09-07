import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';

@Injectable()
export class PlansService {
  constructor(private prisma: PrismaService) {}

  async getActivePlans() {
    return this.prisma.plan.findMany({
      where: { status: 'ACTIVE' },
      include: {
        features: { where: { enabled: true } },
        limits: true,
      },
      orderBy: { monthlyPrice: 'asc' },
    });
  }

  async getPlanBySlug(slug: string) {
    const plan = await this.prisma.plan.findUnique({
      where: { slug, status: 'ACTIVE' },
      include: {
        features: { where: { enabled: true } },
        limits: true,
      },
    });

    if (!plan) {
      throw new NotFoundException(`Plan ${slug} not found or inactive`);
    }

    return plan;
  }
}
