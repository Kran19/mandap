var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { Controller, Get } from '@nestjs/common';
import { HealthCheckService, PrismaHealthIndicator, HealthCheck } from '@nestjs/terminus';
import { PrismaService } from '../prisma.service.js';
let HealthController = class HealthController {
    health;
    prismaHealth;
    prismaService;
    constructor(health, prismaHealth, prismaService) {
        this.health = health;
        this.prismaHealth = prismaHealth;
        this.prismaService = prismaService;
    }
    checkLiveness() {
        return { status: 'ok' };
    }
    checkReadiness() {
        return this.health.check([
            () => this.prismaHealth.pingCheck('database', this.prismaService),
        ]);
    }
};
__decorate([
    Get('live'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], HealthController.prototype, "checkLiveness", null);
__decorate([
    Get('ready'),
    HealthCheck(),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], HealthController.prototype, "checkReadiness", null);
HealthController = __decorate([
    Controller('health'),
    __metadata("design:paramtypes", [HealthCheckService,
        PrismaHealthIndicator,
        PrismaService])
], HealthController);
export { HealthController };
//# sourceMappingURL=health.controller.js.map