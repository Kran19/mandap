var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
import { Controller, Post, Body, HttpCode, HttpStatus, Get, UseGuards } from '@nestjs/common';
import { AuthService } from './auth.service.js';
import { RegisterDto } from './dto/register.dto.js';
import { LoginDto } from './dto/login.dto.js';
import { RefreshDto } from './dto/refresh.dto.js';
import { VerifyEmailDto, SendOtpDto, VerifyOtpDto, VerifyIdentityDto } from './dto/verification.dto.js';
import { UseInterceptors, UploadedFile } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { JwtAuthGuard } from './guards/jwt-auth.guard.js';
import { CurrentUser } from './decorators/current-user.decorator.js';
import { PrismaService } from '../prisma.service.js';
let AuthController = class AuthController {
    authService;
    prisma;
    constructor(authService, prisma) {
        this.authService = authService;
        this.prisma = prisma;
    }
    register(dto) {
        return this.authService.register(dto);
    }
    login(dto) {
        return this.authService.login(dto);
    }
    refresh(dto) {
        return this.authService.refresh(dto);
    }
    logout(dto) {
        return this.authService.logout(dto.refreshToken);
    }
    async getMe(reqUser) {
        const user = await this.prisma.user.findUnique({
            where: { id: reqUser.id },
            include: { organizations: true },
        });
        if (!user)
            return null;
        return {
            id: user.id,
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName,
            status: user.status,
            emailVerified: user.emailVerifiedAt != null,
            mobileVerified: user.mobileVerifiedAt != null,
            identityVerified: user.identityVerifiedAt != null,
            organizationId: user.organizations.length > 0 ? user.organizations[0].organizationId : null,
        };
    }
    verifyEmail(user, dto) {
        return this.authService.verifyEmail(user.id, dto.token);
    }
    sendOtp(user, dto) {
        return this.authService.sendOtp(user.id, dto.phone);
    }
    verifyOtp(user, dto) {
        return this.authService.verifyOtp(user.id, dto.phone, dto.code);
    }
    verifyIdentity(user, dto) {
        return this.authService.verifyIdentity(user.id, dto.identityReference);
    }
    uploadFile(file) {
        return { url: `/uploads/${file.filename}` };
    }
};
__decorate([
    Post('register'),
    __param(0, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [RegisterDto]),
    __metadata("design:returntype", void 0)
], AuthController.prototype, "register", null);
__decorate([
    Post('login'),
    HttpCode(HttpStatus.OK),
    __param(0, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [LoginDto]),
    __metadata("design:returntype", void 0)
], AuthController.prototype, "login", null);
__decorate([
    Post('refresh'),
    HttpCode(HttpStatus.OK),
    __param(0, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [RefreshDto]),
    __metadata("design:returntype", void 0)
], AuthController.prototype, "refresh", null);
__decorate([
    Post('logout'),
    HttpCode(HttpStatus.OK),
    __param(0, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [RefreshDto]),
    __metadata("design:returntype", void 0)
], AuthController.prototype, "logout", null);
__decorate([
    Get('me'),
    UseGuards(JwtAuthGuard),
    __param(0, CurrentUser()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "getMe", null);
__decorate([
    Post('email/verify'),
    UseGuards(JwtAuthGuard),
    __param(0, CurrentUser()),
    __param(1, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, VerifyEmailDto]),
    __metadata("design:returntype", void 0)
], AuthController.prototype, "verifyEmail", null);
__decorate([
    Post('mobile/send-otp'),
    UseGuards(JwtAuthGuard),
    __param(0, CurrentUser()),
    __param(1, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, SendOtpDto]),
    __metadata("design:returntype", void 0)
], AuthController.prototype, "sendOtp", null);
__decorate([
    Post('mobile/verify-otp'),
    UseGuards(JwtAuthGuard),
    __param(0, CurrentUser()),
    __param(1, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, VerifyOtpDto]),
    __metadata("design:returntype", void 0)
], AuthController.prototype, "verifyOtp", null);
__decorate([
    Post('identity/verify'),
    UseGuards(JwtAuthGuard),
    __param(0, CurrentUser()),
    __param(1, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, VerifyIdentityDto]),
    __metadata("design:returntype", void 0)
], AuthController.prototype, "verifyIdentity", null);
__decorate([
    Post('upload'),
    UseInterceptors(FileInterceptor('file', {
        storage: diskStorage({
            destination: './uploads',
            filename: (req, file, cb) => {
                const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
                cb(null, `${file.fieldname}-${uniqueSuffix}${extname(file.originalname)}`);
            },
        }),
    })),
    __param(0, UploadedFile()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], AuthController.prototype, "uploadFile", null);
AuthController = __decorate([
    Controller('auth'),
    __metadata("design:paramtypes", [AuthService,
        PrismaService])
], AuthController);
export { AuthController };
//# sourceMappingURL=auth.controller.js.map