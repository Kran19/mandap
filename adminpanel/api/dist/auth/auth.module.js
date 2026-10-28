var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
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
let AuthModule = class AuthModule {
};
AuthModule = __decorate([
    Global(),
    Module({
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
], AuthModule);
export { AuthModule };
//# sourceMappingURL=auth.module.js.map