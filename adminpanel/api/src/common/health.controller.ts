import { Controller, Get } from '@nestjs/common';
import { HealthCheckService, PrismaHealthIndicator, HealthCheck } from '@nestjs/terminus';
import { PrismaService } from '../prisma.service.js';

@Controller('health')
export class HealthController {
  constructor(
    private health: HealthCheckService,
    private prismaHealth: PrismaHealthIndicator,
    private prismaService: PrismaService,
  ) {}

  @Get('live')
  checkLiveness() {
    // Process is alive
    return { status: 'ok' };
  }

  @Get('ready')
  @HealthCheck()
  checkReadiness() {
    // Checks if the database is responding
    return this.health.check([
      () => this.prismaHealth.pingCheck('database', this.prismaService),
    ]);
  }
}
