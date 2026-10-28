import { Module, Global } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { AuthController } from './auth.controller.js';
import { AuthService } from './auth.service.js';
import { OtpService } from './otp.service.js';
import { DltSmsProvider } from './sms/dlt-sms.provider.js';
import { EmailVerificationProvider } from './email/email-verification.provider.js';
import { JwtStrategy } from './strategies/jwt.strategy.js';
import { JwtAuthGuard } from './guards/jwt-auth.guard.js';
import { OrgRoleGuard } from './guards/org-role.guard.js';
import { AdminPermissionGuard } from './guards/admin-permission.guard.js';
import { PrismaModule } from '../prisma.module.js';

@Global()
@Module({
  imports: [
    PrismaModule,
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.register({}),
  ],
  controllers: [AuthController],
  providers: [
    AuthService,
    OtpService,
    EmailVerificationProvider,
    DltSmsProvider,
    {
      provide: 'SMS_PROVIDER',
      useClass: DltSmsProvider,
    },
    JwtStrategy,
    JwtAuthGuard,
    OrgRoleGuard,
    AdminPermissionGuard,
  ],
  exports: [AuthService, OtpService, EmailVerificationProvider, DltSmsProvider, JwtStrategy, PassportModule, JwtAuthGuard, OrgRoleGuard, AdminPermissionGuard],
})
export class AuthModule {}
