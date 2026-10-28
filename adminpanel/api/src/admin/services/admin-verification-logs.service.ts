import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma.service.js';
import { AdminVerificationLogQueryDto } from '../dto/admin-verification-logs.dto.js';
import { VerificationChannel, VerificationStatus } from '@prisma/client';

@Injectable()
export class AdminVerificationLogsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(query: AdminVerificationLogQueryDto) {
    const { page = 1, limit = 20, channel, status, search, skip } = query;

    const where: any = {};
    if (channel) where.channel = channel;
    if (status) where.status = status;
    if (search) {
      where.OR = [
        { identifier: { contains: search, mode: 'insensitive' } },
        { user: { firstName: { contains: search, mode: 'insensitive' } } },
        { user: { lastName: { contains: search, mode: 'insensitive' } } },
        { user: { email: { contains: search, mode: 'insensitive' } } },
        { user: { phone: { contains: search, mode: 'insensitive' } } },
      ];
    }

    const [data, total, totalSms, totalEmail, totalVerified, totalPending, totalFailed] = await Promise.all([
      this.prisma.verificationLog.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          user: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              phone: true,
              email: true,
              status: true,
              mobileVerifiedAt: true,
              emailVerifiedAt: true,
            },
          },
        },
      }),
      this.prisma.verificationLog.count({ where }),
      this.prisma.verificationLog.count({ where: { channel: VerificationChannel.SMS } }),
      this.prisma.verificationLog.count({ where: { channel: VerificationChannel.EMAIL } }),
      this.prisma.verificationLog.count({ where: { status: VerificationStatus.VERIFIED } }),
      this.prisma.verificationLog.count({ where: { status: VerificationStatus.PENDING } }),
      this.prisma.verificationLog.count({ where: { status: VerificationStatus.FAILED } }),
    ]);

    const totalAll = totalSms + totalEmail;
    const verificationRate = totalAll > 0 ? Math.round((totalVerified / totalAll) * 100) : 0;

    return {
      data,
      stats: {
        totalAll,
        totalSms,
        totalEmail,
        totalVerified,
        totalPending,
        totalFailed,
        verificationRate,
      },
      meta: {
        total,
        page,
        limit,
      },
    };
  }

  async findOne(id: string) {
    const log = await this.prisma.verificationLog.findUnique({
      where: { id },
      include: {
        user: true,
      },
    });

    if (!log) {
      throw new NotFoundException('Verification log entry not found');
    }

    return log;
  }
}
