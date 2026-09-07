import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module.js';
import { PrismaService } from '../src/prisma.service.js';
import { MembershipRole, ProjectStatus } from '@prisma/client';

describe('Projects (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let server: any;
  let ownerToken: string;
  let editorToken: string;
  let viewerToken: string;
  let crossTenantToken: string;
  let orgId: string;
  let crossOrgId: string;

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
      data: { email: 'project-owner@test.com', passwordHash: 'hash', firstName: 'Owner' },
    });
    const editor = await prisma.user.create({
      data: { email: 'project-editor@test.com', passwordHash: 'hash', firstName: 'Editor' },
    });
    const viewer = await prisma.user.create({
      data: { email: 'project-viewer@test.com', passwordHash: 'hash', firstName: 'Viewer' },
    });
    const crossTenantUser = await prisma.user.create({
      data: { email: 'cross-tenant@test.com', passwordHash: 'hash', firstName: 'Cross' },
    });

    const org = await prisma.organization.create({
      data: { name: 'Project Org', slug: 'project-org' },
    });
    orgId = org.id;

    const crossOrg = await prisma.organization.create({
      data: { name: 'Cross Org', slug: 'cross-org' },
    });
    crossOrgId = crossOrg.id;

    await prisma.organizationMember.createMany({
      data: [
        { organizationId: orgId, userId: owner.id, role: MembershipRole.OWNER },
        { organizationId: orgId, userId: editor.id, role: MembershipRole.EDITOR },
        { organizationId: orgId, userId: viewer.id, role: MembershipRole.VIEWER },
        { organizationId: crossOrgId, userId: crossTenantUser.id, role: MembershipRole.OWNER },
      ],
    });

    const plan = await prisma.plan.create({
      data: { name: 'Pro', slug: 'pro-projects', monthlyPrice: 10, yearlyPrice: 100 },
    });
    await prisma.planLimit.create({
      data: { planId: plan.id, key: 'max_projects', value: 2 },
    });
    const sub = await prisma.subscription.create({
      data: { organizationId: orgId, planId: plan.id, provider: 'test', status: 'ACTIVE' },
    });

    const jwtService = moduleFixture.get('JwtService');
    ownerToken = jwtService.sign({ sub: owner.id, email: owner.email });
    editorToken = jwtService.sign({ sub: editor.id, email: editor.email });
    viewerToken = jwtService.sign({ sub: viewer.id, email: viewer.email });
    crossTenantToken = jwtService.sign({ sub: crossTenantUser.id, email: crossTenantUser.email });
  });

  afterAll(async () => {
    await prisma.project.deleteMany();
    await prisma.subscription.deleteMany();
    await prisma.plan.deleteMany();
    await prisma.organization.deleteMany();
    await prisma.user.deleteMany();
    await app.close();
  });

  describe('Project CRUD', () => {
    let projectId: string;

    it('VIEWER cannot create a project', async () => {
      await request(server)
        .post(`/api/v1/organizations/${orgId}/projects`)
        .set('Authorization', `Bearer ${viewerToken}`)
        .send({ name: 'Viewer Project' })
        .expect(403);
    });

    it('EDITOR can create a project', async () => {
      const res = await request(server)
        .post(`/api/v1/organizations/${orgId}/projects`)
        .set('Authorization', `Bearer ${editorToken}`)
        .send({ name: 'Editor Project' })
        .expect(201);
      
      expect(res.body.name).toBe('Editor Project');
      expect(res.body.status).toBe(ProjectStatus.ACTIVE);
    });

    it('OWNER can create a project', async () => {
      const res = await request(server)
        .post(`/api/v1/organizations/${orgId}/projects`)
        .set('Authorization', `Bearer ${ownerToken}`)
        .send({ name: 'Owner Project' })
        .expect(201);
      
      expect(res.body.name).toBe('Owner Project');
      projectId = res.body.id;

      // Verify Audit Log
      const audit = await prisma.auditLog.findFirst({
        where: { resourceId: projectId, action: 'PROJECT_CREATED' },
      });
      expect(audit).toBeDefined();
    });

    it('max_projects entitlement is enforced (limit is 2)', async () => {
      // 3rd project creation should fail
      await request(server)
        .post(`/api/v1/organizations/${orgId}/projects`)
        .set('Authorization', `Bearer ${ownerToken}`)
        .send({ name: 'Over Limit Project' })
        .expect(403);
    });

    it('list projects (VIEWER can read)', async () => {
      const res = await request(server)
        .get(`/api/v1/organizations/${orgId}/projects`)
        .set('Authorization', `Bearer ${viewerToken}`)
        .expect(200);
      
      expect(res.body.data.length).toBe(2);
    });

    it('read single project', async () => {
      const res = await request(server)
        .get(`/api/v1/organizations/${orgId}/projects/${projectId}`)
        .set('Authorization', `Bearer ${viewerToken}`)
        .expect(200);
      
      expect(res.body.id).toBe(projectId);
    });

    it('cross-tenant read is rejected', async () => {
      await request(server)
        .get(`/api/v1/organizations/${crossOrgId}/projects/${projectId}`)
        .set('Authorization', `Bearer ${crossTenantToken}`)
        .expect(404);
    });

    it('cross-tenant list is isolated', async () => {
      const res = await request(server)
        .get(`/api/v1/organizations/${crossOrgId}/projects`)
        .set('Authorization', `Bearer ${crossTenantToken}`)
        .expect(200);
      
      expect(res.body.data.length).toBe(0);
    });

    it('EDITOR can update a project', async () => {
      const res = await request(server)
        .patch(`/api/v1/organizations/${orgId}/projects/${projectId}`)
        .set('Authorization', `Bearer ${editorToken}`)
        .send({ name: 'Updated Name' })
        .expect(200);
      
      expect(res.body.name).toBe('Updated Name');
    });

    it('archive project (OWNER only)', async () => {
      // Viewer cannot
      await request(server)
        .post(`/api/v1/organizations/${orgId}/projects/${projectId}/archive`)
        .set('Authorization', `Bearer ${viewerToken}`)
        .expect(403);
        
      // Owner can
      const res = await request(server)
        .post(`/api/v1/organizations/${orgId}/projects/${projectId}/archive`)
        .set('Authorization', `Bearer ${ownerToken}`)
        .expect(201);
      
      expect(res.body.status).toBe(ProjectStatus.ARCHIVED);
    });

    it('archived project cannot be mutated', async () => {
      await request(server)
        .patch(`/api/v1/organizations/${orgId}/projects/${projectId}`)
        .set('Authorization', `Bearer ${ownerToken}`)
        .send({ name: 'Change' })
        .expect(403);
    });

    it('restore project', async () => {
      const res = await request(server)
        .post(`/api/v1/organizations/${orgId}/projects/${projectId}/restore`)
        .set('Authorization', `Bearer ${ownerToken}`)
        .expect(201);
      
      expect(res.body.status).toBe(ProjectStatus.ACTIVE);
    });
  });
});
