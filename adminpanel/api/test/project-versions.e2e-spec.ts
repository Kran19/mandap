import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module.js';
import { PrismaService } from '../src/prisma.service.js';
import { MembershipRole } from '@prisma/client';

describe('Project Versions (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let server: any;
  let ownerToken: string;
  let orgId: string;
  let projectId: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ transform: true }));
    await app.init();
    server = app.getHttpServer();
    prisma = moduleFixture.get<PrismaService>(PrismaService);

    // Setup Test Data
    const owner = await prisma.user.create({
      data: { email: 'version-owner@test.com', passwordHash: 'hash', firstName: 'Owner' },
    });

    const org = await prisma.organization.create({
      data: { name: 'Version Org', slug: 'version-org' },
    });
    orgId = org.id;

    await prisma.organizationMember.create({
      data: { organizationId: orgId, userId: owner.id, role: MembershipRole.OWNER },
    });

    const plan = await prisma.plan.create({
      data: { name: 'Pro', slug: 'pro-versions', monthlyPrice: 10, yearlyPrice: 100 },
    });
    await prisma.subscription.create({
      data: { organizationId: orgId, planId: plan.id, provider: 'test', status: 'ACTIVE' },
    });
    await prisma.planLimit.create({
      data: { planId: plan.id, key: 'max_projects', value: 10 },
    });

    const jwtService = moduleFixture.get('JwtService');
    ownerToken = jwtService.sign({ sub: owner.id, email: owner.email });

    const project = await request(server)
      .post(`/api/v1/organizations/${orgId}/projects`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ name: 'Version Project' });
    
    projectId = project.body.id;
  });

  afterAll(async () => {
    await prisma.projectVersion.deleteMany();
    await prisma.project.deleteMany();
    await prisma.subscription.deleteMany();
    await prisma.planLimit.deleteMany();
    await prisma.plan.deleteMany();
    await prisma.organizationMember.deleteMany();
    await prisma.organization.deleteMany();
    await prisma.user.deleteMany();
    await app.close();
  });

  describe('Versioning & Concurrency', () => {
    let version1Id: string;
    let version2Id: string;

    const validLayout = {
      schemaVersion: 1,
      layout: {
        nodes: [{ id: 'n1', x: 0, z: 0, type: 'corner', isLocked: false }],
        edges: []
      }
    };

    it('create first version = 1', async () => {
      const res = await request(server)
        .post(`/api/v1/organizations/${orgId}/projects/${projectId}/versions`)
        .set('Authorization', `Bearer ${ownerToken}`)
        .send({ layoutData: validLayout }) // expectedCurrentVersionId optional for first
        .expect(201);
      
      expect(res.body.versionNumber).toBe(1);
      version1Id = res.body.id;
      
      const project = await prisma.project.findUnique({ where: { id: projectId } });
      expect(project?.currentVersionId).toBe(version1Id);
    });

    it('create next version = 2 (optimistic locking check)', async () => {
      const res = await request(server)
        .post(`/api/v1/organizations/${orgId}/projects/${projectId}/versions`)
        .set('Authorization', `Bearer ${ownerToken}`)
        .send({ expectedCurrentVersionId: version1Id, layoutData: validLayout })
        .expect(201);
      
      expect(res.body.versionNumber).toBe(2);
      version2Id = res.body.id;
    });

    it('stale expectedCurrentVersionId -> 409 Conflict', async () => {
      // Trying to save against version1Id again
      const res = await request(server)
        .post(`/api/v1/organizations/${orgId}/projects/${projectId}/versions`)
        .set('Authorization', `Bearer ${ownerToken}`)
        .send({ expectedCurrentVersionId: version1Id, layoutData: validLayout })
        .expect(409);
        
      expect(res.body.message).toContain('Expected current version was');
    });

    it('prevent silent overwrite (no expected version provided on existing)', async () => {
      const res = await request(server)
        .post(`/api/v1/organizations/${orgId}/projects/${projectId}/versions`)
        .set('Authorization', `Bearer ${ownerToken}`)
        .send({ layoutData: validLayout })
        .expect(409);
        
      expect(res.body.message).toContain('must provide expectedCurrentVersionId');
    });

    it('restore old version remains unchanged & creates new version', async () => {
      const res = await request(server)
        .post(`/api/v1/organizations/${orgId}/projects/${projectId}/versions/${version1Id}/restore`)
        .set('Authorization', `Bearer ${ownerToken}`)
        .expect(201);
      
      expect(res.body.versionNumber).toBe(3);
      expect(res.body.metadata.restoredFrom).toBe(version1Id);

      // Verify v1 is still there
      const v1 = await prisma.projectVersion.findUnique({ where: { id: version1Id } });
      expect(v1).toBeDefined();

      // current version is now v3
      const project = await prisma.project.findUnique({ where: { id: projectId } });
      expect(project?.currentVersionId).toBe(res.body.id);
    });

    it('validate schema checks - missing schemaVersion -> 400', async () => {
      await request(server)
        .post(`/api/v1/organizations/${orgId}/projects/${projectId}/versions`)
        .set('Authorization', `Bearer ${ownerToken}`)
        .send({ 
          expectedCurrentVersionId: (await prisma.project.findUnique({where:{id:projectId}}))?.currentVersionId,
          layoutData: { layout: { nodes: [], edges: [] } } 
        })
        .expect(400);
    });
  });
});
