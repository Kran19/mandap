import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module.js';
import { PrismaService } from '../src/prisma.service.js';
import { AdminRole, UserStatus, OrganizationStatus } from '@prisma/client';
import { AuthModule } from '../src/auth/auth.module.js';
import { JwtService } from '@nestjs/jwt';
import { AdminPermissions } from '../src/admin/constants/admin-permissions.js';

describe('Admin APIs (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let jwtService: JwtService;

  let superAdminUser: any;
  let superAdminToken: string;
  let restrictedAdminUser: any;
  let restrictedAdminToken: string;
  let normalUser: any;
  let normalUserToken: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule, AuthModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('api');
    app.enableVersioning({ type: require('@nestjs/common').VersioningType.URI, defaultVersion: '1' });
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
    await app.init();

    prisma = app.get<PrismaService>(PrismaService);
    jwtService = app.get<JwtService>(JwtService);

    // Setup Users
    superAdminUser = await prisma.user.create({
      data: {
        email: `superadmin_${Date.now()}@test.com`,
        passwordHash: 'hash',
        firstName: 'Super',
        lastName: 'Admin',
      },
    });
    restrictedAdminUser = await prisma.user.create({
      data: {
        email: `restricted_${Date.now()}@test.com`,
        passwordHash: 'hash',
        firstName: 'Restricted',
        lastName: 'Admin',
      },
    });
    normalUser = await prisma.user.create({
      data: {
        email: `user_${Date.now()}@test.com`,
        passwordHash: 'hash',
      },
    });

    const jwtSecret = process.env.JWT_ACCESS_SECRET || 'test_secret';
    superAdminToken = jwtService.sign({ sub: superAdminUser.id, email: superAdminUser.email }, { secret: jwtSecret });
    restrictedAdminToken = jwtService.sign({ sub: restrictedAdminUser.id, email: restrictedAdminUser.email }, { secret: jwtSecret });
    normalUserToken = jwtService.sign({ sub: normalUser.id, email: normalUser.email }, { secret: jwtSecret });

    // Setup Roles
    const superAdminRole = await prisma.adminRoleModel.findUnique({ where: { name: AdminRole.SUPER_ADMIN } });
    
    // Ensure 'ADMIN' role exists or recreate it
    let restrictedRole = await prisma.adminRoleModel.findUnique({ where: { name: AdminRole.ADMIN } });
    if (!restrictedRole) {
      restrictedRole = await prisma.adminRoleModel.create({
        data: {
          name: AdminRole.ADMIN,
          description: 'Restricted Admin',
          isActive: true,
        },
      });
    } else {
      restrictedRole = await prisma.adminRoleModel.update({
        where: { id: restrictedRole.id },
        data: { isActive: true }
      });
    }

    // Clean old permissions
    await prisma.adminPermission.deleteMany({ where: { roleId: restrictedRole.id } });
    // Add only read
    await prisma.adminPermission.create({
      data: { roleId: restrictedRole.id, action: AdminPermissions.USERS_READ },
    });

    // Setup Admin Memberships
    await prisma.adminMembership.create({
      data: { userId: superAdminUser.id, roleId: superAdminRole!.id, isActive: true },
    });
    await prisma.adminMembership.create({
      data: { userId: restrictedAdminUser.id, roleId: restrictedRole.id, isActive: true },
    });
  });

  afterAll(async () => {
    // Clean up created entities
    await prisma.adminMembership.deleteMany({
      where: { user: { email: { contains: `admin_` } } }
    });
    await prisma.user.deleteMany({
      where: { email: { contains: `admin_` } }
    });
    await prisma.user.deleteMany({
      where: { email: { contains: `test-` } }
    });
    await prisma.adminRoleModel.update({
      where: { name: AdminRole.ADMIN },
      data: { isActive: false }
    }).catch(() => {});
    await prisma.user.deleteMany({
      where: { id: { in: [superAdminUser.id, restrictedAdminUser.id, normalUser.id] } },
    });
    await prisma.$disconnect();
    await app.close();
  });

  describe('IDOR & Privilege Escalation', () => {
    it('Normal user CANNOT access Admin Users API -> 403 Forbidden', async () => {
      const response = await request(app.getHttpServer())
        .get('/api/v1/admin/users')
        .set('Authorization', `Bearer ${normalUserToken}`);
      
      expect(response.status).toBe(403);
    });

    it('Restricted admin CAN access granted API (USERS_READ)', async () => {
      const response = await request(app.getHttpServer())
        .get('/api/v1/admin/users')
        .set('Authorization', `Bearer ${restrictedAdminToken}`);
      
      expect(response.status).toBe(200);
      expect(response.body.data).toBeInstanceOf(Array);
      expect(response.body.meta).toBeDefined();
    });

    it('Restricted admin CANNOT access ungranted API (USERS_WRITE)', async () => {
      const response = await request(app.getHttpServer())
        .patch(`/api/v1/admin/users/${normalUser.id}`)
        .set('Authorization', `Bearer ${restrictedAdminToken}`)
        .send({ status: UserStatus.SUSPENDED });
      
      expect(response.status).toBe(403);
    });

    it('Restricted admin CANNOT access ungranted API (ORGANIZATIONS_READ)', async () => {
      const response = await request(app.getHttpServer())
        .get('/api/v1/admin/organizations')
        .set('Authorization', `Bearer ${restrictedAdminToken}`);
      
      expect(response.status).toBe(403);
    });

    it('Restricted admin CAN read their own profile and permissions from /admin/me', async () => {
      const response = await request(app.getHttpServer())
        .get('/api/v1/admin/me')
        .set('Authorization', `Bearer ${restrictedAdminToken}`);

      expect(response.status).toBe(200);
      expect(response.body.email).toBe(restrictedAdminUser.email);
      expect(response.body.roles.length).toBeGreaterThan(0);
      expect(response.body.roles[0].permissions.some((p: any) => p.action === AdminPermissions.USERS_READ)).toBe(true);
    });
  });

  describe('Pagination & Filters', () => {
    it('GET /admin/users enforces default limit', async () => {
      const response = await request(app.getHttpServer())
        .get('/api/v1/admin/users')
        .set('Authorization', `Bearer ${superAdminToken}`);
      
      expect(response.status).toBe(200);
      expect(response.body.meta.limit).toBe(20);
      expect(response.body.meta.page).toBe(1);
    });

    it('GET /admin/users accepts limit and offset', async () => {
      const response = await request(app.getHttpServer())
        .get('/api/v1/admin/users?limit=2&page=1')
        .set('Authorization', `Bearer ${superAdminToken}`);
      
      expect(response.status).toBe(200);
      expect(response.body.meta.limit).toBe(2);
      expect(response.body.data.length).toBeLessThanOrEqual(2);
    });
  });

  describe('User Status Lifecycle (Session Revocation & Auditing)', () => {
    it('Suspending a user logs the audit event', async () => {
      // 1. Suspend the user
      const response = await request(app.getHttpServer())
        .patch(`/api/v1/admin/users/${normalUser.id}`)
        .set('Authorization', `Bearer ${superAdminToken}`)
        .send({ status: UserStatus.SUSPENDED });
      
      expect(response.status).toBe(200);
      expect(response.body.status).toBe(UserStatus.SUSPENDED);

      // 2. Verify Audit Log was created
      const auditLog = await prisma.auditLog.findFirst({
        where: { adminId: superAdminUser.id, action: 'USER_STATUS_CHANGED', resourceId: normalUser.id },
      });
      expect(auditLog).toBeDefined();
      expect(auditLog?.action).toBe('USER_STATUS_CHANGED');
    });
  });

  describe('Validation Constraints', () => {
    it('Creating a plan with duplicate slug -> 409 Conflict', async () => {
      const planDto = {
        name: 'Test Plan',
        slug: `plan_${Date.now()}`,
        monthlyPrice: 1000,
        yearlyPrice: 10000,
      };

      // Create first time
      await request(app.getHttpServer())
        .post('/api/v1/admin/plans')
        .set('Authorization', `Bearer ${superAdminToken}`)
        .send(planDto)
        .expect(201);

      // Create second time with same key
      const response = await request(app.getHttpServer())
        .post('/api/v1/admin/plans')
        .set('Authorization', `Bearer ${superAdminToken}`)
        .send(planDto);

      expect(response.status).toBe(409);
    });
  });
});
