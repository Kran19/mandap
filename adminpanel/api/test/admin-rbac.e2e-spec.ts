import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe, VersioningType } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module.js';
import { PrismaService } from '../src/prisma.service.js';
import * as argon2 from 'argon2';
import { AdminRole, UserStatus } from '@prisma/client';
import { AdminPermissions } from '../src/admin/constants/admin-permissions.js';

describe('Admin RBAC Hardening (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  let superAdminToken: string;
  let supportAdminToken: string;
  let customerUserToken: string;
  let unauthorizedAdminToken: string;

  let superAdminUserId: string;
  let targetOrgId: string;
  let dummyUserId: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('api');
    app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });
    app.useGlobalPipes(new ValidationPipe({ whitelist: true }));
    prisma = app.get<PrismaService>(PrismaService);
    await app.init();

    // Clean up specific test data if needed, but avoid global deleteMany to allow parallel execution
    const passwordHash = await argon2.hash('Password123!');

    // 1. Fetch existing Seeded Roles
    const superRole = await prisma.adminRoleModel.findUnique({ where: { name: AdminRole.SUPER_ADMIN } });
    const supportRole = await prisma.adminRoleModel.findUnique({ where: { name: AdminRole.SUPPORT } });

    if (!superRole || !supportRole) {
      throw new Error('Roles must be seeded before running E2E tests.');
    }

    // Create a temporary unauthorized role
    const unauthorizedRole = await prisma.adminRoleModel.upsert({
      where: { name: AdminRole.OPERATIONS },
      update: {
        description: 'Unauthorized Role for testing',
        isActive: true,
        permissions: {
          deleteMany: {},
          create: [{ action: AdminPermissions.USERS_READ }], // Missing ORGANIZATIONS_READ
        },
      },
      create: {
        name: AdminRole.OPERATIONS,
        description: 'Unauthorized Role for testing',
        permissions: {
          create: [{ action: AdminPermissions.USERS_READ }], // Missing ORGANIZATIONS_READ
        },
      },
    });

    // 2. Setup Users
    const superAdmin = await prisma.user.create({
      data: {
        email: 'superadmin@test.fake',
        passwordHash,
        status: UserStatus.ACTIVE,
        adminMembership: {
          create: { roleId: superRole.id, isActive: true },
        },
      },
    });
    superAdminUserId = superAdmin.id;

    const supportAdmin = await prisma.user.create({
      data: {
        email: 'supportadmin@test.fake',
        passwordHash,
        status: UserStatus.ACTIVE,
        adminMembership: {
          create: { roleId: supportRole.id, isActive: true },
        },
      },
    });

    const unauthorizedAdmin = await prisma.user.create({
      data: {
        email: 'unauthadmin@test.fake',
        passwordHash,
        status: UserStatus.ACTIVE,
        adminMembership: {
          create: { roleId: unauthorizedRole.id, isActive: true },
        },
      },
    });

    const customerUser = await prisma.user.create({
      data: { email: 'customer@test.fake', passwordHash, status: UserStatus.ACTIVE },
    });

    const dummyUser = await prisma.user.create({
      data: { email: 'dummy@test.fake', passwordHash, status: UserStatus.ACTIVE },
    });
    dummyUserId = dummyUser.id;

    // 3. Setup Organization (Customer Context)
    const org = await prisma.organization.create({
      data: {
        name: 'Test Org',
        slug: 'test-org',
        members: {
          create: [{ userId: customerUser.id, role: 'OWNER' }],
        },
      },
    });
    targetOrgId = org.id;

    // 4. Authenticate Users
    const login = async (email: string) => {
      const res = await request(app.getHttpServer())
        .post('/api/v1/auth/login')
        .send({ email, password: 'Password123!' })
        .expect(200);
      return res.body.accessToken;
    };

    superAdminToken = await login('superadmin@test.fake');
    supportAdminToken = await login('supportadmin@test.fake');
    customerUserToken = await login('customer@test.fake');
    unauthorizedAdminToken = await login('unauthadmin@test.fake');
  });

  afterAll(async () => {
    // Cleanup created records for this test specifically
    await prisma.projectVersion.deleteMany({ where: { project: { organizationId: targetOrgId } } });
    await prisma.project.deleteMany({ where: { organizationId: targetOrgId } });
    await prisma.subscription.deleteMany({ where: { organizationId: targetOrgId } });
    await prisma.organizationMember.deleteMany({ where: { organizationId: targetOrgId } });
    await prisma.organization.deleteMany({ where: { id: targetOrgId } });
    await prisma.adminMembership.deleteMany({
      where: { user: { email: { in: ['superadmin@test.fake', 'supportadmin@test.fake', 'unauthadmin@test.fake'] } } },
    });
    await prisma.user.deleteMany({
      where: { email: { in: ['superadmin@test.fake', 'supportadmin@test.fake', 'unauthadmin@test.fake', 'customer@test.fake', 'dummy@test.fake'] } },
    });
    // We don't delete OPERATIONS role since it's an enum, just clean up the user.
    await app.close();
  });

  describe('Customer / Admin Separation', () => {
    it('Customer OWNER cannot access admin endpoints', async () => {
      await request(app.getHttpServer())
        .get(`/api/v1/admin/organizations/${targetOrgId}`)
        .set('Authorization', `Bearer ${customerUserToken}`)
        .expect(403);
    });

    it('Admin with correct permission CAN access explicitly permitted tenant', async () => {
      await request(app.getHttpServer())
        .get(`/api/v1/admin/organizations/${targetOrgId}`)
        .set('Authorization', `Bearer ${supportAdminToken}`)
        .expect(200);
    });

    it('Admin without correct permission CANNOT access tenant through admin path', async () => {
      await request(app.getHttpServer())
        .get(`/api/v1/admin/organizations/${targetOrgId}`)
        .set('Authorization', `Bearer ${unauthorizedAdminToken}`)
        .expect(403);
    });

    it('Unauthenticated requests are denied (401)', async () => {
      await request(app.getHttpServer())
        .get(`/api/v1/admin/organizations/${targetOrgId}`)
        .expect(401);
    });
  });

  describe('Privilege Escalation Protection', () => {
    it('Support Admin cannot grant SUPER_ADMIN', async () => {
      await request(app.getHttpServer())
        .post(`/api/v1/admin/roles/grant-super-admin/${dummyUserId}`)
        .set('Authorization', `Bearer ${supportAdminToken}`)
        .expect(403);
    });

    it('Customer OWNER cannot grant SUPER_ADMIN', async () => {
      await request(app.getHttpServer())
        .post(`/api/v1/admin/roles/grant-super-admin/${dummyUserId}`)
        .set('Authorization', `Bearer ${customerUserToken}`)
        .expect(403);
    });

    it('SUPER_ADMIN can grant SUPER_ADMIN', async () => {
      await request(app.getHttpServer())
        .post(`/api/v1/admin/roles/grant-super-admin/${dummyUserId}`)
        .set('Authorization', `Bearer ${superAdminToken}`)
        .expect(201); // 201 Created because it's a POST
    });

    it('Cannot revoke the last SUPER_ADMIN (Self Lockout Protection)', async () => {
      // First, revoke the dummy user's SUPER_ADMIN we just granted
      await request(app.getHttpServer())
        .post(`/api/v1/admin/roles/revoke-super-admin/${dummyUserId}`)
        .set('Authorization', `Bearer ${superAdminToken}`)
        .expect(201);

      // Now attempt to revoke the ONLY remaining SUPER_ADMIN
      const res = await request(app.getHttpServer())
        .post(`/api/v1/admin/roles/revoke-super-admin/${superAdminUserId}`)
        .set('Authorization', `Bearer ${superAdminToken}`)
        .expect(403);

      expect(res.body.message).toContain('Cannot remove the final active SUPER_ADMIN');
    });
  });

  describe('Admin Membership Lifecycle', () => {
    it('Inactive admin membership cannot authorize requests', async () => {
      // Deactivate the support admin's membership directly in the DB
      await prisma.adminMembership.updateMany({
        where: { user: { email: 'supportadmin@test.fake' } },
        data: { isActive: false },
      });

      await request(app.getHttpServer())
        .get(`/api/v1/admin/organizations/${targetOrgId}`)
        .set('Authorization', `Bearer ${supportAdminToken}`)
        .expect(403);
    });
  });
});
