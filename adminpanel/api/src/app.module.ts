import { Module } from '@nestjs/common';
import { ThrottlerModule } from '@nestjs/throttler';
import { LoggerModule } from 'nestjs-pino';
import { randomUUID } from 'crypto';
import Joi from 'joi';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';
import { PrismaModule } from './prisma.module.js';
import { AuthModule } from './auth/auth.module.js';
import { APP_FILTER } from '@nestjs/core';
import { PrismaClientExceptionFilter } from './common/filters/prisma-client-exception.filter.js';
import { OrganizationsModule } from './organizations/organizations.module.js';
import { AdminModule } from './admin/admin.module.js';
import { BillingModule } from './billing/billing.module.js';
import { ProjectsModule } from './projects/projects.module.js';
import { TerminusModule } from '@nestjs/terminus';
import { HealthController } from './common/health.controller.js';
import { AllExceptionsFilter } from './common/filters/all-exceptions.filter.js';
import { RedisModule } from './redis/redis.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      validationSchema: Joi.object({
        NODE_ENV: Joi.string().valid('development', 'production', 'test').default('development'),
        PORT: Joi.number().default(3001),
        DATABASE_URL: Joi.string().required(),
        JWT_SECRET: Joi.string().required(),
        JWT_EXPIRATION_TIME: Joi.string().default('15m'),
        FRONTEND_URL: Joi.string().required(),
      }),
    }),
    PrismaModule,
    RedisModule,
    AuthModule,
    LoggerModule.forRoot({
      pinoHttp: {
        level: process.env.NODE_ENV !== 'production' ? 'debug' : 'info',
        transport: process.env.NODE_ENV !== 'production' ? { target: 'pino-pretty' } : undefined,
        genReqId: (req) => req.headers['x-request-id'] || randomUUID(),
      },
    }),
    ThrottlerModule.forRoot([
      {
        name: 'default',
        ttl: 60000,
        limit: 500, // increased for dev: hot-reload causes many rapid GETs
      },
      {
        name: 'auth',
        ttl: 900000, // 15 mins
        limit: 10,
      },
      {
        name: 'versions',
        ttl: 60000, // 1 min
        limit: 200, // increased so project loads don't 429 during dev
      }
    ]),
    OrganizationsModule,
    AdminModule,
    BillingModule,
    ProjectsModule,
    TerminusModule,
  ],
  controllers: [AppController, HealthController],
  providers: [
    AppService,
    {
      provide: APP_FILTER,
      useClass: AllExceptionsFilter,
    },
    {
      provide: APP_FILTER,
      useClass: PrismaClientExceptionFilter,
    },
  ],
})
export class AppModule {}
