import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, VersioningType, HttpStatus } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module.js';
import { PrismaService } from './../src/prisma.service.js';
import * as argon2 from 'argon2';
import { MembershipRole } from '@prisma/client';

describe('Organizations & Memberships (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;

  let ownerToken: string;
  let ownerId: string;
  let editorToken: string;
  let editorId: string;
  let newMemberToken: string;
  let newMemberId: string;
  let otherOrgOwnerToken: string;
  let otherOrgOwnerId: string;
  
  let orgId: string;
  let otherOrgId: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('api');
    app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });
    await app.init();

    prisma = app.get<PrismaService>(PrismaService);
    
    // Seed test users
    const passwordHash = await argon2.hash('Password123!');
    
    // Owner User
    const ownerUser = await prisma.user.create({
      data: { email: 'owner-org@test.fake', passwordHash }
    });
    ownerId = ownerUser.id;
    
    // Editor User
    const editorUser = await prisma.user.create({
      data: { email: 'editor-org@test.fake', passwordHash }
    });
    editorId = editorUser.id;
    
    // New Member User
    const newMemberUser = await prisma.user.create({
      data: { email: 'newmember-org@test.fake', passwordHash }
    });
    newMemberId = newMemberUser.id;

    // Other Org Owner User
    const otherOwnerUser = await prisma.user.create({
      data: { email: 'otherowner-org@test.fake', passwordHash }
    });
    otherOrgOwnerId = otherOwnerUser.id;

    // Login users to get tokens
    const loginOwner = await request(app.getHttpServer()).post('/api/v1/auth/login').send({ email: 'owner-org@test.fake', password: 'Password123!' }).expect(200);
    ownerToken = loginOwner.body.accessToken;
    
    const loginEditor = await request(app.getHttpServer()).post('/api/v1/auth/login').send({ email: 'editor-org@test.fake', password: 'Password123!' }).expect(200);
    editorToken = loginEditor.body.accessToken;

    const loginNewMember = await request(app.getHttpServer()).post('/api/v1/auth/login').send({ email: 'newmember-org@test.fake', password: 'Password123!' }).expect(200);
    newMemberToken = loginNewMember.body.accessToken;

    const loginOtherOwner = await request(app.getHttpServer()).post('/api/v1/auth/login').send({ email: 'otherowner-org@test.fake', password: 'Password123!' }).expect(200);
    otherOrgOwnerToken = loginOtherOwner.body.accessToken;
  });

  afterAll(async () => {
    // Cleanup
    if (prisma) {
      await prisma.organizationMember.deleteMany({
        where: { user: { email: { endsWith: '-org@test.fake' } } }
      });
      await prisma.organization.deleteMany({
        where: { slug: { startsWith: 'test-org-' } }
      });
      await prisma.user.deleteMany({
        where: { email: { endsWith: '-org@test.fake' } }
      });
    }
    if (app) await app.close();
  });

  // ------------------------------------------------------------------
  // 1. Organization Creation & Listing
  // ------------------------------------------------------------------
  it('POST /organizations (creates an org, assigns creator as OWNER)', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/v1/organizations')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ name: 'Test Org 1' })
      .expect(201);
    
    expect(res.body.id).toBeDefined();
    expect(res.body.slug).toBe('test-org-1');
    expect(res.body.name).toBe('Test Org 1');
    orgId = res.body.id;

    // Verify ownership
    const membership = await prisma.organizationMember.findUnique({
      where: { organizationId_userId: { organizationId: orgId, userId: ownerId } }
    });
    expect(membership?.role).toBe(MembershipRole.OWNER);
  });

  it('POST /organizations (handles slug collision safely)', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/v1/organizations')
      .set('Authorization', `Bearer ${otherOrgOwnerToken}`)
      .send({ name: 'Test Org 1' })
      .expect(201);
    
    expect(res.body.slug).toBe('test-org-1-2');
    otherOrgId = res.body.id;
  });

  it('GET /organizations (returns only user\'s organizations)', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/v1/organizations')
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);
    
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBe(1);
    expect(res.body[0].id).toBe(orgId);
    expect(res.body[0].role).toBe(MembershipRole.OWNER);
  });

  // ------------------------------------------------------------------
  // 2. Organization Retrieval & Update (RBAC + Tenant Isolation)
  // ------------------------------------------------------------------
  it('GET /organizations/:orgId (OWNER can read)', async () => {
    await request(app.getHttpServer())
      .get(`/api/v1/organizations/${orgId}`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);
  });

  it('GET /organizations/:orgId (Non-member CANNOT read -> 403 Forbidden)', async () => {
    await request(app.getHttpServer())
      .get(`/api/v1/organizations/${orgId}`)
      .set('Authorization', `Bearer ${otherOrgOwnerToken}`)
      .expect(403);
  });

  it('PATCH /organizations/:orgId (OWNER can update metadata)', async () => {
    const res = await request(app.getHttpServer())
      .patch(`/api/v1/organizations/${orgId}`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ name: 'Test Org 1 Updated' })
      .expect(200);
    expect(res.body.name).toBe('Test Org 1 Updated');
  });

  // ------------------------------------------------------------------
  // 3. Membership Management
  // ------------------------------------------------------------------
  it('POST /organizations/:orgId/members (OWNER can add member by email)', async () => {
    const res = await request(app.getHttpServer())
      .post(`/api/v1/organizations/${orgId}/members`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ email: 'editor-org@test.fake', role: MembershipRole.EDITOR })
      .expect(201);
    expect(res.body.message).toBe('Member added successfully');
  });

  it('POST /organizations/:orgId/members (Fails if adding as OWNER)', async () => {
    await request(app.getHttpServer())
      .post(`/api/v1/organizations/${orgId}/members`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ email: 'newmember-org@test.fake', role: MembershipRole.OWNER })
      .expect(400); // 400 Bad Request
  });

  it('GET /organizations/:orgId/members (EDITOR can list members)', async () => {
    const res = await request(app.getHttpServer())
      .get(`/api/v1/organizations/${orgId}/members`)
      .set('Authorization', `Bearer ${editorToken}`)
      .expect(200);
    expect(res.body.length).toBe(2);
  });

  it('PATCH /organizations/:orgId (EDITOR CANNOT update metadata -> 403)', async () => {
    await request(app.getHttpServer())
      .patch(`/api/v1/organizations/${orgId}`)
      .set('Authorization', `Bearer ${editorToken}`)
      .send({ name: 'Hacked Name' })
      .expect(403);
  });

  it('POST /organizations/:orgId/members (EDITOR CANNOT add member -> 403)', async () => {
    await request(app.getHttpServer())
      .post(`/api/v1/organizations/${orgId}/members`)
      .set('Authorization', `Bearer ${editorToken}`)
      .send({ email: 'newmember-org@test.fake', role: MembershipRole.VIEWER })
      .expect(403);
  });

  // Add the new member as VIEWER using the OWNER token for future tests
  it('Setup: OWNER adds newMember as VIEWER', async () => {
    await request(app.getHttpServer())
      .post(`/api/v1/organizations/${orgId}/members`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ email: 'newmember-org@test.fake', role: MembershipRole.VIEWER })
      .expect(201);
  });

  // ------------------------------------------------------------------
  // 4. Role Updates & Ownership Invariants
  // ------------------------------------------------------------------
  it('PATCH /organizations/:orgId/members/:userId (OWNER changes VIEWER -> EDITOR)', async () => {
    await request(app.getHttpServer())
      .patch(`/api/v1/organizations/${orgId}/members/${newMemberId}`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ role: MembershipRole.EDITOR })
      .expect(200);
  });

  it('PATCH /organizations/:orgId/members/:userId (OWNER CANNOT change member -> OWNER directly)', async () => {
    await request(app.getHttpServer())
      .patch(`/api/v1/organizations/${orgId}/members/${newMemberId}`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ role: MembershipRole.OWNER })
      .expect(400); // 400 Bad Request
  });

  it('DELETE /organizations/:orgId/members/:userId (OWNER CANNOT remove themselves)', async () => {
    await request(app.getHttpServer())
      .delete(`/api/v1/organizations/${orgId}/members/${ownerId}`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(400);
  });

  // ------------------------------------------------------------------
  // 5. Ownership Transfer
  // ------------------------------------------------------------------
  it('POST /organizations/:orgId/ownership-transfer (OWNER transfers to EDITOR)', async () => {
    await request(app.getHttpServer())
      .post(`/api/v1/organizations/${orgId}/ownership-transfer`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ newOwnerId: editorId })
      .expect(200);

    // Verify db state
    const oldOwner = await prisma.organizationMember.findUnique({ where: { organizationId_userId: { organizationId: orgId, userId: ownerId } } });
    const newOwner = await prisma.organizationMember.findUnique({ where: { organizationId_userId: { organizationId: orgId, userId: editorId } } });
    
    expect(oldOwner?.role).toBe(MembershipRole.EDITOR);
    expect(newOwner?.role).toBe(MembershipRole.OWNER);
  });

  it('POST /organizations/:orgId/ownership-transfer (Old owner CANNOT transfer again)', async () => {
    await request(app.getHttpServer())
      .post(`/api/v1/organizations/${orgId}/ownership-transfer`)
      .set('Authorization', `Bearer ${ownerToken}`) // now an EDITOR
      .send({ newOwnerId: newMemberId })
      .expect(403);
  });

  // ------------------------------------------------------------------
  // 6. Leaving & Removal
  // ------------------------------------------------------------------
  it('POST /organizations/:orgId/leave (Sole owner CANNOT leave)', async () => {
    // editorId is the new owner
    await request(app.getHttpServer())
      .post(`/api/v1/organizations/${orgId}/leave`)
      .set('Authorization', `Bearer ${editorToken}`)
      .expect(400);
  });

  it('POST /organizations/:orgId/leave (Non-owner CAN leave)', async () => {
    // newMemberId is an EDITOR, can leave
    await request(app.getHttpServer())
      .post(`/api/v1/organizations/${orgId}/leave`)
      .set('Authorization', `Bearer ${newMemberToken}`)
      .expect(200);
  });

  it('DELETE /organizations/:orgId/members/:userId (New OWNER removes old owner)', async () => {
    await request(app.getHttpServer())
      .delete(`/api/v1/organizations/${orgId}/members/${ownerId}`)
      .set('Authorization', `Bearer ${editorToken}`) // editorToken is now the OWNER
      .expect(200);
  });

});
