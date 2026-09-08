import { Test, TestingModule } from '@nestjs/testing';
import { OtpService } from './otp.service.js';
import { REDIS_CLIENT } from '../redis/redis.module.js';
import { UnauthorizedException, TooManyRequestsException } from '@nestjs/common';
import * as argon2 from 'argon2';
import { vi } from 'vitest';

vi.mock('argon2', () => ({
  hash: vi.fn(),
  verify: vi.fn(),
}));

describe('OtpService', () => {
  let service: OtpService;
  let mockRedis: any;
  let mockSms: any;

  beforeEach(async () => {
    mockRedis = {
      set: vi.fn(),
      get: vi.fn(),
      del: vi.fn(),
    };

    mockSms = {
      sendSms: vi.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OtpService,
        { provide: REDIS_CLIENT, useValue: mockRedis },
        { provide: 'SMS_PROVIDER', useValue: mockSms },
      ],
    }).compile();

    service = module.get<OtpService>(OtpService);
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  describe('generateAndSendOtp', () => {
    it('should generate OTP, hash it, store in redis, and send SMS', async () => {
      (argon2.hash as any).mockResolvedValue('hashed_otp');

      const challengeId = await service.generateAndSendOtp('u1', '+14155552671');

      expect(challengeId).toBeDefined();
      expect(mockRedis.set).toHaveBeenCalledTimes(1);
      
      const setArgs = mockRedis.set.mock.calls[0];
      expect(setArgs[0]).toBe(`login_challenge:${challengeId}`);
      expect(setArgs[2]).toBe('EX');
      expect(setArgs[3]).toBe(300); // 5 mins TTL

      const storedData = JSON.parse(setArgs[1]);
      expect(storedData.userId).toBe('u1');
      expect(storedData.otpHash).toBe('hashed_otp');
      expect(storedData.attemptCount).toBe(0);

      expect(mockSms.sendSms).toHaveBeenCalledTimes(1);
      expect(mockSms.sendSms.mock.calls[0][0]).toBe('+14155552671');
    });
  });

  describe('verifyOtp', () => {
    const validData = {
      userId: 'u1',
      otpHash: 'hashed_otp',
      attemptCount: 0,
      createdAt: new Date().toISOString(),
      expiresAt: new Date(Date.now() + 300000).toISOString(),
    };

    it('should return userId on successful verification and clean up Redis key', async () => {
      mockRedis.get.mockResolvedValue(JSON.stringify(validData));
      (argon2.verify as any).mockResolvedValue(true);

      const userId = await service.verifyOtp('challenge_123', '123456');

      expect(userId).toBe('u1');
      expect(mockRedis.del).toHaveBeenCalledWith('login_challenge:challenge_123');
      expect(mockRedis.set).not.toHaveBeenCalled(); // doesn't update, just deletes
    });

    it('should throw UnauthorizedException if challenge not found or expired', async () => {
      mockRedis.get.mockResolvedValue(null);

      await expect(service.verifyOtp('challenge_123', '123456')).rejects.toThrow(UnauthorizedException);
    });

    it('should increment attemptCount and throw UnauthorizedException on wrong OTP', async () => {
      mockRedis.get.mockResolvedValue(JSON.stringify(validData));
      (argon2.verify as any).mockResolvedValue(false);

      await expect(service.verifyOtp('challenge_123', 'wrong')).rejects.toThrow(UnauthorizedException);

      // It should update the Redis key with attemptCount + 1
      expect(mockRedis.set).toHaveBeenCalledTimes(1);
      const setArgs = mockRedis.set.mock.calls[0];
      const updatedData = JSON.parse(setArgs[1]);
      expect(updatedData.attemptCount).toBe(1);
    });

    it('should throw TooManyRequestsException if attemptCount is already at max', async () => {
      mockRedis.get.mockResolvedValue(JSON.stringify({ ...validData, attemptCount: 5 }));

      await expect(service.verifyOtp('challenge_123', '123456')).rejects.toThrow(TooManyRequestsException);
      
      // Shouldn't even verify the hash
      expect(argon2.verify).not.toHaveBeenCalled();
    });
  });
});
