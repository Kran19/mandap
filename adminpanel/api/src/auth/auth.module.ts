import { Module, Global } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { AuthController } from './auth.controller.js';
import { AuthService } from './auth.service.js';
import { OtpService } from './otp.service.js';
import { DevelopmentSmsProvider } from './sms/development-sms.provider.js';
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
    {
      provide: 'SMS_PROVIDER',
      useClass: process.env.NODE_ENV === 'production' ? DevelopmentSmsProvider : DevelopmentSmsProvider, // TODO: ProductionSmsProvider
    },
    JwtStrategy,
    JwtAuthGuard,
    OrgRoleGuard,
    AdminPermissionGuard,
  ],
  exports: [AuthService, OtpService, JwtStrategy, PassportModule, JwtAuthGuard, OrgRoleGuard, AdminPermissionGuard],
})
export class AuthModule {}
