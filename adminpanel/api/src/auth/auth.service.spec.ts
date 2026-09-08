import { Test, TestingModule } from '@nestjs/testing';
import { AuthService } from './auth.service.js';
import { PrismaService } from '../prisma.service.js';
import { JwtService } from '@nestjs/jwt';
import { OtpService } from './otp.service.js';
import { UserStatus } from '@prisma/client';
import * as argon2 from 'argon2';
import { UnauthorizedException } from '@nestjs/common';
import { vi } from 'vitest';

vi.mock('argon2', () => ({
  verify: vi.fn(),
  hash: vi.fn(),
}));

describe('AuthService', () => {
  let service: AuthService;
  let prisma: PrismaService;
  let otpService: OtpService;

  const mockPrisma = {
    user: {
      findUnique: vi.fn(),
      update: vi.fn(),
    },
    refreshSession: {
      create: vi.fn(),
    },
  };

  const mockJwt = {
    sign: vi.fn(),
  };

  const mockOtp = {
    generateAndSendOtp: vi.fn(),
    verifyOtp: vi.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: JwtService, useValue: mockJwt },
        { provide: OtpService, useValue: mockOtp },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
    prisma = module.get<PrismaService>(PrismaService);
    otpService = module.get<OtpService>(OtpService);
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  describe('login', () => {
    it('should trigger OTP challenge for valid phone and password', async () => {
      const mockUser = { id: 'u1', phone: '+14155552671', passwordHash: 'hash', status: UserStatus.ACTIVE };
      mockPrisma.user.findUnique.mockResolvedValue(mockUser);
      (argon2.verify as any).mockResolvedValue(true);
      mockOtp.generateAndSendOtp.mockResolvedValue('challenge_123');

      const result = await service.login({ phone: '+14155552671', password: 'password123' });

      expect(result).toEqual({
        otpRequired: true,
        challengeId: 'challenge_123',
      });
      expect(otpService.generateAndSendOtp).toHaveBeenCalledWith('u1', '+14155552671');
    });

    it('should give generic UnauthorizedException for wrong password', async () => {
      const mockUser = { id: 'u1', phone: '+14155552671', passwordHash: 'hash', status: UserStatus.ACTIVE };
      mockPrisma.user.findUnique.mockResolvedValue(mockUser);
      (argon2.verify as any).mockResolvedValue(false);

      await expect(service.login({ phone: '+14155552671', password: 'wrong' }))
        .rejects.toThrow(UnauthorizedException);
        
      expect(otpService.generateAndSendOtp).not.toHaveBeenCalled();
    });

    it('should give generic UnauthorizedException for unknown phone (no account enumeration)', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(null);

      // E.164 compliant but unknown phone
      await expect(service.login({ phone: '+14155552672', password: 'password' }))
        .rejects.toThrow(UnauthorizedException);
    });

    it('should give generic UnauthorizedException for INACTIVE user', async () => {
      const mockUser = { id: 'u1', phone: '+14155552671', passwordHash: 'hash', status: UserStatus.INACTIVE };
      mockPrisma.user.findUnique.mockResolvedValue(mockUser);

      await expect(service.login({ phone: '+14155552671', password: 'password' }))
        .rejects.toThrow(UnauthorizedException);
    });
  });

  describe('verifyLoginOtp', () => {
    it('should return tokens on valid OTP', async () => {
      mockOtp.verifyOtp.mockResolvedValue('u1');
      const mockUser = { id: 'u1', phone: '+14155552671', email: 'test@test.com' };
      mockPrisma.user.findUnique.mockResolvedValue(mockUser);
      mockJwt.sign.mockReturnValue('token');

      const result = await service.verifyLoginOtp('challenge_123', '123456');

      expect(result).toHaveProperty('accessToken', 'token');
      expect(result).toHaveProperty('refreshToken', 'token');
      expect(otpService.verifyOtp).toHaveBeenCalledWith('challenge_123', '123456');
    });
  });
});
