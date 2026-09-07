import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, VersioningType } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module.js';
import { PrismaService } from './../src/prisma.service.js';
import { MembershipRole } from '@prisma/client';
import * as argon2 from 'argon2';

describe('Authorization & Tenant Isolation (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  
  let userAToken: string;
  let userBToken: string;
  let adminToken: string;
  
  let orgAId: string;
  let orgBId: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('api');
    app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });
    await app.init();

    prisma = app.get<PrismaService>(PrismaService);
    
    // Seed test data for isolation
    const passwordHash = await argon2.hash('Password123!');
    
    // User A & Org A
    const userA = await prisma.user.create({
      data: {
        email: 'usera@test.fake',
        passwordHash,
      }
    });
    const orgA = await prisma.organization.create({
      data: { name: 'Org A', slug: 'org-a-test' }
    });
    await prisma.organizationMember.create({
      data: { userId: userA.id, organizationId: orgA.id, role: MembershipRole.OWNER }
    });
    
    // User B & Org B
    const userB = await prisma.user.create({
      data: {
        email: 'userb@test.fake',
        passwordHash,
      }
    });
    const orgB = await prisma.organization.create({
      data: { name: 'Org B', slug: 'org-b-test' }
    });
    await prisma.organizationMember.create({
      data: { userId: userB.id, organizationId: orgB.id, role: MembershipRole.EDITOR }
    });
    
    // Admin User
    const adminUser = await prisma.user.create({
      data: {
        email: 'admin_rbac@test.fake',
        passwordHash,
      }
    });
    const supportRole = await prisma.adminRoleModel.findFirst({ where: { name: 'SUPPORT' } });
    if (supportRole) {
      const mem = await prisma.adminMembership.create({
        data: { userId: adminUser.id, roleId: supportRole.id }
      });
      console.log('Created admin membership:', mem);
    } else {
      console.log('SUPPORT ROLE NOT FOUND IN DB!');
    }

    orgAId = orgA.id;
    orgBId = orgB.id;

    // Login users to get tokens
    const loginA = await request(app.getHttpServer()).post('/api/v1/auth/login').send({ email: 'usera@test.fake', password: 'Password123!' }).expect(200);
    userAToken = loginA.body.accessToken;
    
    const loginB = await request(app.getHttpServer()).post('/api/v1/auth/login').send({ email: 'userb@test.fake', password: 'Password123!' }).expect(200);
    userBToken = loginB.body.accessToken;
    
    const loginAdmin = await request(app.getHttpServer()).post('/api/v1/auth/login').send({ email: 'admin_rbac@test.fake', password: 'Password123!' }).expect(200);
    adminToken = loginAdmin.body.accessToken;
  });

  afterAll(async () => {
    // Cleanup
    if (prisma) {
      await prisma.organizationMember.deleteMany({ where: { organizationId: { in: [orgAId, orgBId] } } });
      await prisma.organization.deleteMany({ where: { id: { in: [orgAId, orgBId] } } });
      await prisma.adminMembership.deleteMany({ where: { user: { email: 'admin_rbac@test.fake' } } });
      await prisma.user.deleteMany({ where: { email: { in: ['usera@test.fake', 'userb@test.fake', 'admin_rbac@test.fake'] } } });
    }
    if (app) await app.close();
  });

  // TENANT ISOLATION TESTS
  it('User A can access Org A', async () => {
    const res = await request(app.getHttpServer())
      .get(`/api/v1/organizations/${orgAId}/members`)
      .set('Authorization', `Bearer ${userAToken}`);
    
    if (res.status !== 200) {
      console.error('User A access Org A failed:', res.body);
    }
    
    expect(res.status).toBe(200);
  });

  it('User B can access Org B', async () => {
    await request(app.getHttpServer())
      .get(`/api/v1/organizations/${orgBId}/members`)
      .set('Authorization', `Bearer ${userBToken}`)
      .expect(200);
  });

  it('User A CANNOT access Org B (Tenant Isolation)', async () => {
    await request(app.getHttpServer())
      .get(`/api/v1/organizations/${orgBId}/members`)
      .set('Authorization', `Bearer ${userAToken}`)
      .expect(403);
  });

  it('User B CANNOT access Org A (Tenant Isolation)', async () => {
    await request(app.getHttpServer())
      .get(`/api/v1/organizations/${orgAId}/members`)
      .set('Authorization', `Bearer ${userBToken}`)
      .expect(403);
  });

  // ADMIN RBAC TESTS
  it('Customer User A CANNOT access admin endpoints', async () => {
    await request(app.getHttpServer())
      .get(`/api/v1/admin/organizations/${orgAId}`)
      .set('Authorization', `Bearer ${userAToken}`)
      .expect(403);
  });

  it('Admin User CAN access admin endpoints', async () => {
    const res = await request(app.getHttpServer())
      .get(`/api/v1/admin/organizations/${orgAId}`)
      .set('Authorization', `Bearer ${adminToken}`);
    
    if (res.status !== 200) {
      console.error('Admin User access admin endpoints failed:', res.body);
    }

    expect(res.status).toBe(200);
  });
});
