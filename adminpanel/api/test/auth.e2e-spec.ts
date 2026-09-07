import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, VersioningType } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module.js';
import { PrismaService } from './../src/prisma.service.js';

describe('Auth (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('api');
    app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });
    await app.init();

    prisma = app.get<PrismaService>(PrismaService);
  });

  afterAll(async () => {
    // Cleanup created users
    if (prisma) {
      await prisma.user.deleteMany({
        where: { email: { startsWith: 'test-auth' } },
      });
    }
    if (app) await app.close();
  });

  const testEmail = 'test-auth-user@mandap.fake';
  const testPassword = 'Password123!';
  let accessToken: string;
  let refreshToken: string;

  it('/api/v1/auth/register (POST) - success', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/register')
      .send({ email: testEmail, password: testPassword })
      .expect(201);

    expect(response.body).toHaveProperty('accessToken');
    expect(response.body).toHaveProperty('refreshToken');
    accessToken = response.body.accessToken;
    refreshToken = response.body.refreshToken;
  });

  it('/api/v1/auth/register (POST) - duplicate email', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/auth/register')
      .send({ email: testEmail, password: testPassword })
      .expect(400);
  });

  it('/api/v1/auth/login (POST) - success', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({ email: testEmail, password: testPassword })
      .expect(200);

    expect(response.body).toHaveProperty('accessToken');
    expect(response.body).toHaveProperty('refreshToken');
    accessToken = response.body.accessToken;
    refreshToken = response.body.refreshToken;
  });

  it('/api/v1/auth/login (POST) - invalid password', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({ email: testEmail, password: 'wrongpassword' })
      .expect(401);
  });

  it('/api/v1/auth/me (GET) - success', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);

    expect(response.body.email).toBe(testEmail);
    expect(response.body.status).toBe('ACTIVE');
  });

  it('/api/v1/auth/refresh (POST) - success', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/refresh')
      .send({ refreshToken })
      .expect(200);

    expect(response.body).toHaveProperty('accessToken');
    expect(response.body).toHaveProperty('refreshToken');
    
    // update tokens for the next test
    accessToken = response.body.accessToken;
    const oldRefreshToken = refreshToken;
    refreshToken = response.body.refreshToken;

    // Test token reuse (sending the old one again)
    await request(app.getHttpServer())
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: oldRefreshToken })
      .expect(401); // Expecting reuse detection to invalidate
  });

  it('/api/v1/auth/logout (POST) - success', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/auth/logout')
      .send({ refreshToken })
      .expect(200);

    // After logout, refresh should fail
    await request(app.getHttpServer())
      .post('/api/v1/auth/refresh')
      .send({ refreshToken })
      .expect(401);
  });
});
