import { Test, TestingModule } from '@nestjs/testing';
import { PrismaService } from '../src/prisma.service.js';
import { PrismaClientKnownRequestError } from '@prisma/client/runtime/library';
import { describe, beforeAll, afterAll, it, expect } from 'vitest';

describe('Database Schema & Constraints (e2e)', () => {
  let prisma: PrismaService;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      providers: [PrismaService],
    }).compile();

    prisma = moduleFixture.get<PrismaService>(PrismaService);
    await prisma.onModuleInit();
  });

  afterAll(async () => {
    // Clean up any stray data from tests
    await prisma.organization.deleteMany({ where: { slug: 'test-org-e2e' } });
    await prisma.user.deleteMany({ where: { email: 'test-e2e@mandap.fake' } });
    await prisma.onModuleDestroy();
  });

  it('should fail to create duplicate organization members', async () => {
    const user = await prisma.user.create({
      data: { email: 'test-e2e@mandap.fake', passwordHash: 'hash' },
    });

    const org = await prisma.organization.create({
      data: { name: 'Test Org', slug: 'test-org-e2e' },
    });

    // First membership
    await prisma.organizationMember.create({
      data: { organizationId: org.id, userId: user.id, role: 'EDITOR' },
    });

    // Duplicate membership should fail
    await expect(
      prisma.organizationMember.create({
        data: { organizationId: org.id, userId: user.id, role: 'VIEWER' },
      }),
    ).rejects.toMatchObject({ code: 'P2002' });
  });
});
