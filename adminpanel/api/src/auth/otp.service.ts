import { Injectable, Inject, Logger, BadRequestException, UnauthorizedException, HttpException, HttpStatus } from '@nestjs/common';
import { REDIS_CLIENT } from '../redis/redis.module.js';
import { Redis } from 'ioredis';
import type { SmsProvider } from './sms/sms.provider.js';
import { randomUUID } from 'crypto';
import * as argon2 from 'argon2';

@Injectable()
export class OtpService {
  private readonly logger = new Logger(OtpService.name);
  
  // 5 minutes expiry for OTP
  private readonly OTP_TTL_SECONDS = 300;
  private readonly MAX_ATTEMPTS = 5;

  private readonly inMemoryFallback = new Map<string, { data: string; expiresAt: number }>();

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

    const serialized = JSON.stringify(data);
    try {
      await this.redis.set(key, serialized, 'EX', this.OTP_TTL_SECONDS);
    } catch (err) {
      this.logger.warn(`Redis set failed, falling back to memory: ${err}`);
      this.inMemoryFallback.set(key, {
        data: serialized,
        expiresAt: Date.now() + this.OTP_TTL_SECONDS * 1000,
      });
    }

    // Send the SMS
    this.logger.log(`[OTP GENERATED] Phone: ${phone} | OTP: ${otp}`);
    await this.smsProvider.sendSms(phone, `Your MANDAP verification code is: ${otp}. It expires in 5 minutes.`);
    
    return challengeId;
  }

  async verifyOtp(challengeId: string, otp: string): Promise<string> {
    const key = `login_challenge:${challengeId}`;
    
    let rawData: string | null = null;
    try {
      rawData = await this.redis.get(key);
    } catch (err) {
      this.logger.warn(`Redis get failed, falling back to memory: ${err}`);
    }

    if (!rawData) {
      const fallback = this.inMemoryFallback.get(key);
      if (fallback && fallback.expiresAt > Date.now()) {
        rawData = fallback.data;
      }
    }

    if (!rawData) {
      throw new UnauthorizedException('OTP challenge expired or invalid');
    }

    const data = JSON.parse(rawData);

    if (data.attemptCount >= this.MAX_ATTEMPTS) {
      throw new HttpException('Maximum OTP attempts exceeded', HttpStatus.TOO_MANY_REQUESTS);
    }

    const isValid = await argon2.verify(data.otpHash, otp);
    
    if (!isValid) {
      // Increment attempt count
      data.attemptCount += 1;
      // Calculate remaining TTL to preserve expiration
      const expiresAt = new Date(data.expiresAt).getTime();
      const remainingTtl = Math.max(1, Math.floor((expiresAt - Date.now()) / 1000));
      
      const updated = JSON.stringify(data);
      try {
        await this.redis.set(key, updated, 'EX', remainingTtl);
      } catch (_) {
        this.inMemoryFallback.set(key, { data: updated, expiresAt });
      }
      throw new UnauthorizedException('Invalid OTP');
    }

    // OTP is valid, consume it (delete from Redis and memory to prevent reuse)
    try {
      await this.redis.del(key);
    } catch (_) {}
    this.inMemoryFallback.delete(key);

    return data.userId;
  }
}
