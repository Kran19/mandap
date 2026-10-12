import { Injectable, OnModuleInit, OnModuleDestroy, Logger } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PrismaService.name);

  constructor() {
    super();
  }

  async onModuleInit() {
    await this.$connect();
    try {
      await this.$executeRawUnsafe(`ALTER TABLE "User" ALTER COLUMN "email" DROP NOT NULL;`);
    } catch (e: any) {
      this.logger.warn(`Schema self-healing note: ${e.message}`);
    }
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
