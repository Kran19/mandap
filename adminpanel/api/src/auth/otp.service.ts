import { Injectable, Inject, Logger, BadRequestException, UnauthorizedException, HttpException, HttpStatus } from '@nestjs/common';
import { REDIS_CLIENT } from '../redis/redis.module.js';
import { Redis } from 'ioredis';
import type { SmsProvider } from './sms/sms.provider.js';
import { EmailVerificationProvider } from './email/email-verification.provider.js';
import { PrismaService } from '../prisma.service.js';
import { randomUUID } from 'crypto';
import * as argon2 from 'argon2';
import { VerificationChannel, VerificationPurpose, VerificationStatus } from '@prisma/client';

@Injectable()
export class OtpService {
  private readonly logger = new Logger(OtpService.name);
  
  // 5 minutes expiry for OTP
  private readonly OTP_TTL_SECONDS = 300;
  private readonly OTP_COOLDOWN_SECONDS = 60;
  private readonly MAX_ATTEMPTS = 5;

  private readonly inMemoryFallback = new Map<string, { data: string; expiresAt: number }>();

  constructor(
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
    @Inject('SMS_PROVIDER') private readonly smsProvider: SmsProvider,
    private readonly emailProvider: EmailVerificationProvider,
    private readonly prisma: PrismaService,
  ) {}

  /**
   * Identifies test numbers (for Google Play / App Store review and QA)
   */
  isTestPhoneNumber(phone: string): boolean {
    const cleaned = phone.replace(/[^0-9]/g, '');
    return cleaned === '9999999999' || cleaned === '919999999999';
  }

  /**
   * Generates a 6-digit secure numeric code
   */
  generateRandomCode(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  /**
   * Dispatches DLT SMS OTP and records into VerificationLog
   */
  async generateAndSendOtp(
    userId: string,
    phone: string,
    candidateName?: string,
    purpose: VerificationPurpose = VerificationPurpose.LOGIN,
  ): Promise<string> {
    const cleanPhone = phone.replace(/[^0-9]/g, '');
    const cooldownKey = `otp_cooldown:sms:${cleanPhone}`;

    // 1. Enforce 60-second cooldown per phone number to prevent rapid/duplicate dispatches
    let isCooldownActive = false;
    try {
      const active = await this.redis.get(cooldownKey);
      if (active) isCooldownActive = true;
    } catch (_) {
      const fallback = this.inMemoryFallback.get(cooldownKey);
      if (fallback && fallback.expiresAt > Date.now()) {
        isCooldownActive = true;
      }
    }

    if (isCooldownActive) {
      this.logger.warn(`[OTP THROTTLED] ${cleanPhone} requested OTP within 60s cooldown window.`);
      throw new HttpException(
        'Please wait 60 seconds before requesting another OTP.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    const challengeId = randomUUID();
    const otp = this.generateRandomCode();
    const otpHash = await argon2.hash(otp);
    const expiresAt = new Date(Date.now() + this.OTP_TTL_SECONDS * 1000);

    const key = `login_challenge:${challengeId}`;
    const data = {
      challengeId,
      userId,
      phone,
      otpHash,
      attemptCount: 0,
      createdAt: new Date().toISOString(),
      expiresAt: expiresAt.toISOString(),
      purpose,
    };

    const serialized = JSON.stringify(data);
    try {
      await this.redis.set(key, serialized, 'EX', this.OTP_TTL_SECONDS);
      await this.redis.set(cooldownKey, '1', 'EX', this.OTP_COOLDOWN_SECONDS);
    } catch (err) {
      this.logger.warn(`Redis set failed, falling back to memory: ${err}`);
      this.inMemoryFallback.set(key, {
        data: serialized,
        expiresAt: expiresAt.getTime(),
      });
      this.inMemoryFallback.set(cooldownKey, {
        data: '1',
        expiresAt: Date.now() + this.OTP_COOLDOWN_SECONDS * 1000,
      });
    }

    // Dispatch via SMS Provider (DLT Gateway)
    let gatewayMsgId: string | undefined;
    let gatewayStatus: string | undefined;

    // Check if designated test number (e.g. Google Play Console / reviewer test account)
    if (this.isTestPhoneNumber(phone)) {
      gatewayStatus = 'Test Account - SMS Bypassed';
      this.logger.log(`[TEST ACCOUNT OTP BYPASS] Recipient: ${phone} | Challenge: ${challengeId} | Static OTP 123456 accepted`);
    } else if (this.smsProvider.sendOtpSms) {
      const result = await this.smsProvider.sendOtpSms(phone, otp, candidateName);
      gatewayMsgId = result.messageId;
      gatewayStatus = result.statusSummary;
    } else {
      const sent = await this.smsProvider.sendSms(
        phone,
        `Dear ${candidateName || 'Candidate'} Your OTP for verification is ${otp}. Please enter this code to complete the process.\nRegards MANDAP\nTEXT2`,
      );
      gatewayStatus = sent ? 'Sent successfully' : 'Failed to send';
    }

    // Persist in Prisma VerificationLog for tracking in Admin Panel
    try {
      const logEntry = await this.prisma.verificationLog.create({
        data: {
          id: challengeId,
          userId,
          identifier: phone,
          channel: VerificationChannel.SMS,
          purpose,
          codeHash: otpHash,
          status: VerificationStatus.PENDING,
          gatewayMsgId,
          gatewayStatus,
          expiresAt,
          metadata: {
            candidateName: candidateName || 'Candidate',
            channel: 'SMS',
          },
        },
      });
      this.logger.log(`[VerificationLog Created] ID: ${logEntry.id} | Channel: SMS | Recipient: ${phone}`);
    } catch (dbErr) {
      this.logger.error(`Failed to record VerificationLog: ${dbErr}`);
    }

    this.logger.log(`[OTP GENERATED] Phone: ${phone} | OTP: ${otp} | ChallengeId: ${challengeId}`);
    return challengeId;
  }

  /**
   * Dispatches Email Verification Code and records into VerificationLog
   */
  async generateAndSendEmailCode(
    userId: string,
    email: string,
    candidateName?: string,
    purpose: VerificationPurpose = VerificationPurpose.REGISTRATION,
  ): Promise<string> {
    const cleanEmail = email.trim().toLowerCase();
    const emailCooldownKey = `otp_cooldown:email:${cleanEmail}`;

    // 1. Enforce 60-second cooldown per email address
    let isEmailCooldownActive = false;
    try {
      const active = await this.redis.get(emailCooldownKey);
      if (active) isEmailCooldownActive = true;
    } catch (_) {
      const fallback = this.inMemoryFallback.get(emailCooldownKey);
      if (fallback && fallback.expiresAt > Date.now()) {
        isEmailCooldownActive = true;
      }
    }

    if (isEmailCooldownActive) {
      this.logger.warn(`[EMAIL OTP THROTTLED] ${cleanEmail} requested code within 60s cooldown window.`);
      throw new HttpException(
        'Please wait 60 seconds before requesting another verification code.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    const challengeId = randomUUID();
    const code = this.generateRandomCode();
    const codeHash = await argon2.hash(code);
    const expiresAt = new Date(Date.now() + this.OTP_TTL_SECONDS * 1000);

    const key = `email_challenge:${challengeId}`;
    const userEmailKey = `user_email_pending:${userId}`;
    const data = {
      challengeId,
      userId,
      email,
      codeHash,
      attemptCount: 0,
      createdAt: new Date().toISOString(),
      expiresAt: expiresAt.toISOString(),
      purpose,
    };

    const serialized = JSON.stringify(data);
    try {
      await this.redis.set(key, serialized, 'EX', this.OTP_TTL_SECONDS);
      await this.redis.set(userEmailKey, challengeId, 'EX', this.OTP_TTL_SECONDS);
      await this.redis.set(emailCooldownKey, '1', 'EX', this.OTP_COOLDOWN_SECONDS);
    } catch (err) {
      this.logger.warn(`Redis set failed, falling back to memory: ${err}`);
      this.inMemoryFallback.set(key, {
        data: serialized,
        expiresAt: expiresAt.getTime(),
      });
      this.inMemoryFallback.set(userEmailKey, {
        data: challengeId,
        expiresAt: expiresAt.getTime(),
      });
      this.inMemoryFallback.set(emailCooldownKey, {
        data: '1',
        expiresAt: Date.now() + this.OTP_COOLDOWN_SECONDS * 1000,
      });
    }

    // Dispatch via Email Provider
    const result = await this.emailProvider.sendVerificationEmail(email, code, candidateName);

    // Persist in Prisma VerificationLog
    try {
      await this.prisma.verificationLog.create({
        data: {
          id: challengeId,
          userId,
          identifier: email,
          channel: VerificationChannel.EMAIL,
          purpose,
          codeHash,
          status: VerificationStatus.PENDING,
          gatewayMsgId: result.messageId,
          gatewayStatus: result.statusSummary,
          expiresAt,
          metadata: {
            candidateName: candidateName || 'Candidate',
            channel: 'EMAIL',
          },
        },
      });
    } catch (dbErr) {
      this.logger.error(`Failed to record Email VerificationLog: ${dbErr}`);
    }

    this.logger.log(`[EMAIL CODE GENERATED] Email: ${email} | Code: ${code} | ChallengeId: ${challengeId}`);
    return challengeId;
  }

  /**
   * Verifies an OTP challenge (for Login or Mobile/Email validation)
   */
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

    // Also fallback to check database if Redis was restarted
    let dbRecord: any = null;
    if (!rawData) {
      dbRecord = await this.prisma.verificationLog.findUnique({
        where: { id: challengeId },
      });
      if (!dbRecord || dbRecord.expiresAt < new Date()) {
        throw new UnauthorizedException('OTP challenge expired or invalid');
      }
    }

    const data = rawData ? JSON.parse(rawData) : {
      userId: dbRecord.userId,
      otpHash: dbRecord.codeHash,
      attemptCount: dbRecord.attempts,
      expiresAt: dbRecord.expiresAt.toISOString(),
    };

    if (data.attemptCount >= this.MAX_ATTEMPTS) {
      await this.prisma.verificationLog.update({
        where: { id: challengeId },
        data: { status: VerificationStatus.FAILED },
      }).catch(() => {});
      throw new HttpException('Maximum OTP attempts exceeded', HttpStatus.TOO_MANY_REQUESTS);
    }

    // Accept real code or '123456' as development/test fallback
    const isDevelopment = process.env.NODE_ENV !== 'production';
    const isTestNumber = data.phone ? this.isTestPhoneNumber(data.phone) : false;
    const isDevBypass = (isDevelopment || isTestNumber) && otp === '123456';
    const isValid = isDevBypass || (await argon2.verify(data.otpHash, otp));
    
    if (!isValid) {
      data.attemptCount += 1;
      const expiresAt = new Date(data.expiresAt).getTime();
      const remainingTtl = Math.max(1, Math.floor((expiresAt - Date.now()) / 1000));
      
      const updated = JSON.stringify(data);
      try {
        await this.redis.set(key, updated, 'EX', remainingTtl);
      } catch (_) {
        this.inMemoryFallback.set(key, { data: updated, expiresAt });
      }

      await this.prisma.verificationLog.update({
        where: { id: challengeId },
        data: { attempts: data.attemptCount },
      }).catch(() => {});

      throw new UnauthorizedException('Invalid OTP');
    }

    // Mark verified in VerificationLog
    try {
      await this.prisma.verificationLog.update({
        where: { id: challengeId },
        data: {
          status: VerificationStatus.VERIFIED,
          verifiedAt: new Date(),
          attempts: data.attemptCount + 1,
        },
      });
    } catch (_) {}

    // Consume challenge
    try {
      await this.redis.del(key);
    } catch (_) {}
    this.inMemoryFallback.delete(key);

    return data.userId;
  }

  /**
   * Verifies Email Code by token or by userId
   */
  async verifyEmailCode(userId: string, code: string): Promise<boolean> {
    const isDevelopment = process.env.NODE_ENV !== 'production';
    if (isDevelopment && code === '123456') {
      await this.prisma.verificationLog.updateMany({
        where: { userId, channel: VerificationChannel.EMAIL, status: VerificationStatus.PENDING },
        data: { status: VerificationStatus.VERIFIED, verifiedAt: new Date() },
      }).catch(() => {});
      return true;
    }

    // Find latest pending verification log for this user & email channel
    const log = await this.prisma.verificationLog.findFirst({
      where: {
        userId,
        channel: VerificationChannel.EMAIL,
        status: VerificationStatus.PENDING,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!log) {
      // Check if user has any pending challenge
      throw new BadRequestException('No pending email verification code found or code expired.');
    }

    const isValid = await argon2.verify(log.codeHash, code);
    if (!isValid) {
      await this.prisma.verificationLog.update({
        where: { id: log.id },
        data: { attempts: { increment: 1 } },
      }).catch(() => {});
      throw new BadRequestException('Invalid email verification code.');
    }

    await this.prisma.verificationLog.update({
      where: { id: log.id },
      data: {
        status: VerificationStatus.VERIFIED,
        verifiedAt: new Date(),
        attempts: { increment: 1 },
      },
    });

    return true;
  }

  /**
   * Verifies Mobile OTP directly for logged-in user
   */
  async verifyMobileCode(userId: string, phone: string, code: string): Promise<boolean> {
    const isDevelopment = process.env.NODE_ENV !== 'production';
    const isTestNumber = this.isTestPhoneNumber(phone);
    if ((isDevelopment || isTestNumber) && code === '123456') {
      await this.prisma.verificationLog.updateMany({
        where: { userId, channel: VerificationChannel.SMS, status: VerificationStatus.PENDING },
        data: { status: VerificationStatus.VERIFIED, verifiedAt: new Date() },
      }).catch(() => {});
      return true;
    }

    const log = await this.prisma.verificationLog.findFirst({
      where: {
        userId,
        channel: VerificationChannel.SMS,
        status: VerificationStatus.PENDING,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!log) {
      throw new BadRequestException('No pending mobile OTP found or code expired.');
    }

    const isValid = await argon2.verify(log.codeHash, code);
    if (!isValid) {
      await this.prisma.verificationLog.update({
        where: { id: log.id },
        data: { attempts: { increment: 1 } },
      }).catch(() => {});
      throw new BadRequestException('Invalid mobile OTP.');
    }

    await this.prisma.verificationLog.update({
      where: { id: log.id },
      data: {
        status: VerificationStatus.VERIFIED,
        verifiedAt: new Date(),
        attempts: { increment: 1 },
      },
    });

    return true;
  }
}
