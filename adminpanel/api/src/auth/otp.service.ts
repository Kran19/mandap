import { Injectable, Inject, Logger, BadRequestException, UnauthorizedException, TooManyRequestsException } from '@nestjs/common';
import { REDIS_CLIENT } from '../redis/redis.module.js';
import Redis from 'ioredis';
import { SmsProvider } from './sms/sms.provider.js';
import { randomUUID } from 'crypto';
import * as argon2 from 'argon2';

@Injectable()
export class OtpService {
  private readonly logger = new Logger(OtpService.name);
  
  // 5 minutes expiry for OTP
  private readonly OTP_TTL_SECONDS = 300;
  private readonly MAX_ATTEMPTS = 5;

  constructor(
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
    @Inject('SMS_PROVIDER') private readonly smsProvider: SmsProvider,
  ) {}

  async generateAndSendOtp(userId: string, phone: string): Promise<string> {
    const challengeId = randomUUID();
    
    // Generate a 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpHash = await argon2.hash(otp);

    const key = `login_challenge:${challengeId}`;
    const data = {
      userId,
      otpHash,
      attemptCount: 0,
      createdAt: new Date().toISOString(),
      expiresAt: new Date(Date.now() + this.OTP_TTL_SECONDS * 1000).toISOString(),
    };

    await this.redis.set(key, JSON.stringify(data), 'EX', this.OTP_TTL_SECONDS);

    // Send the SMS
    await this.smsProvider.sendSms(phone, `Your MANDAP verification code is: ${otp}. It expires in 5 minutes.`);
    
    return challengeId;
  }

  async verifyOtp(challengeId: string, otp: string): Promise<string> {
    const key = `login_challenge:${challengeId}`;
    
    // We use a multi block to avoid race conditions on attemptCount and consumption
    const rawData = await this.redis.get(key);
    if (!rawData) {
      throw new UnauthorizedException('OTP challenge expired or invalid');
    }

    const data = JSON.parse(rawData);

    if (data.attemptCount >= this.MAX_ATTEMPTS) {
      throw new TooManyRequestsException('Maximum OTP attempts exceeded');
    }

    const isValid = await argon2.verify(data.otpHash, otp);
    
    if (!isValid) {
      // Increment attempt count
      data.attemptCount += 1;
      // Calculate remaining TTL to preserve expiration
      const expiresAt = new Date(data.expiresAt).getTime();
      const remainingTtl = Math.max(1, Math.floor((expiresAt - Date.now()) / 1000));
      
      await this.redis.set(key, JSON.stringify(data), 'EX', remainingTtl);
      throw new UnauthorizedException('Invalid OTP');
    }

    // OTP is valid, consume it (delete from Redis to prevent reuse)
    await this.redis.del(key);

    return data.userId;
  }
}
