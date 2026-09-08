import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, VersioningType } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module.js';
import { PrismaService } from './../src/prisma.service.js';
import { REDIS_CLIENT } from './../src/redis/redis.module.js';
import Redis from 'ioredis';
import { normalizePhone } from './../src/utils/phone.util.js';
import { vi } from 'vitest';

describe('Auth & OTP (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let redis: Redis;

  const testPhone = '+14155552671';
  const otherPhone = '+14155552672';
  const testPassword = 'Password123!';

  // Stub SMS provider to intercept OTP codes
  const mockSmsProvider = {
    sendSms: vi.fn().mockResolvedValue(true),
  };

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider('SMS_PROVIDER')
      .useValue(mockSmsProvider)
      .compile();

    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('api');
    app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });
    await app.init();

    prisma = app.get<PrismaService>(PrismaService);
    redis = app.get<Redis>(REDIS_CLIENT);
  });

  afterAll(async () => {
    // Cleanup created users
    if (prisma) {
      await prisma.user.deleteMany({
        where: { phone: { in: [normalizePhone(testPhone), normalizePhone(otherPhone)] } },
      });
    }
    if (app) await app.close();
  });

  beforeEach(() => {
    mockSmsProvider.sendSms.mockClear();
  });

  let challengeId: string;
  let sentOtp: string;

  it('/api/v1/auth/register (POST) - success with phone', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/register')
      .send({ phone: testPhone, password: testPassword })
      .expect(201);

    expect(response.body).toHaveProperty('success', true);
  });

  it('/api/v1/auth/login (POST) - success triggers OTP', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({ phone: testPhone, password: testPassword })
      .expect(200);

    expect(response.body).toHaveProperty('challengeId');
    expect(response.body).toHaveProperty('requireOtp', true);
    challengeId = response.body.challengeId;

    // Verify SMS was dispatched
    expect(mockSmsProvider.sendSms).toHaveBeenCalledTimes(1);
    const smsMessage = mockSmsProvider.sendSms.mock.calls[0][1];
    
    // Extract OTP from the SMS message "Your MANDAP verification code is: 123456..."
    const match = smsMessage.match(/code is: (\d{6})/);
    expect(match).toBeTruthy();
    sentOtp = match![1];
  });

  it('/api/v1/auth/login (POST) - wrong password gives generic failure', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({ phone: testPhone, password: 'wrongpassword' })
      .expect(401);
    
    expect(response.body.message).toBe('Invalid credentials.');
  });

  it('/api/v1/auth/login (POST) - unknown phone gives generic failure', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({ phone: '+12345678901', password: 'Password123!' })
      .expect(401);

    expect(response.body.message).toBe('Invalid credentials.');
  });

  it('/api/v1/auth/login/verify-otp (POST) - wrong OTP increments attempts', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/login/verify-otp')
      .send({ challengeId, otp: '000000' })
      .expect(401);

    expect(response.body.message).toBe('Invalid OTP');

    // Check redis key exists and attempts incremented
    const rawData = await redis.get(`login_challenge:${challengeId}`);
    expect(rawData).toBeTruthy();
    const data = JSON.parse(rawData!);
    expect(data.attemptCount).toBe(1);
  });

  it('/api/v1/auth/login/verify-otp (POST) - max attempts invalidates challenge', async () => {
    // Current attempt is 1. We will fail 4 more times to reach 5
    for (let i = 0; i < 4; i++) {
      await request(app.getHttpServer())
        .post('/api/v1/auth/login/verify-otp')
        .send({ challengeId, otp: '000000' })
        .expect(401); // 401 for Invalid OTP, but on the 5th attempt it might throw 429
    }

    // Now it should throw TooManyRequestsException
    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/login/verify-otp')
      .send({ challengeId, otp: sentOtp }) // even correct OTP fails if max attempts reached
      .expect(429);
      
    expect(response.body.message).toBe('Maximum OTP attempts exceeded');
  });

  it('generates a new challenge when logging in again, and old challenge is effectively orphaned/ignored', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({ phone: testPhone, password: testPassword })
      .expect(200);

    challengeId = response.body.challengeId;
    
    expect(mockSmsProvider.sendSms).toHaveBeenCalledTimes(1);
    const match = mockSmsProvider.sendSms.mock.calls[0][1].match(/code is: (\d{6})/);
    sentOtp = match![1];
  });

  it('/api/v1/auth/login/verify-otp (POST) - correct OTP issues JWT and cleans up Redis', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/login/verify-otp')
      .send({ challengeId, otp: sentOtp })
      .expect(200);

    expect(response.body).toHaveProperty('accessToken');
    expect(response.body).toHaveProperty('refreshToken');
    
    // Verify Redis key is deleted
    const rawData = await redis.get(`login_challenge:${challengeId}`);
    expect(rawData).toBeNull();
  });

  it('/api/v1/auth/login/verify-otp (POST) - reused OTP rejected (key deleted)', async () => {
    // Try to verify again with the same challenge ID and OTP
    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/login/verify-otp')
      .send({ challengeId, otp: sentOtp })
      .expect(401);

    expect(response.body.message).toBe('OTP challenge expired or invalid');
  });

  it('OTP from user A cannot authenticate user B', async () => {
    // Register user B
    await request(app.getHttpServer())
      .post('/api/v1/auth/register')
      .send({ phone: otherPhone, password: testPassword })
      .expect(201);

    // Login user B
    const bRes = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({ phone: otherPhone, password: testPassword })
      .expect(200);
    
    const bChallengeId = bRes.body.challengeId;
    
    // Login user A
    const aRes = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({ phone: testPhone, password: testPassword })
      .expect(200);
      
    // The latest sms is to user A
    const aOtp = mockSmsProvider.sendSms.mock.calls[mockSmsProvider.sendSms.mock.calls.length - 1][1].match(/code is: (\d{6})/)[1];
    
    // Attempt to verify user B's challenge using user A's OTP
    await request(app.getHttpServer())
      .post('/api/v1/auth/login/verify-otp')
      .send({ challengeId: bChallengeId, otp: aOtp })
      .expect(401);
  });
});
