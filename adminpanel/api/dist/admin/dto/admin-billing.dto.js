var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { IsOptional, IsString, IsInt, Min, IsNumber } from 'class-validator';
import { Type } from 'class-transformer';
export class AdminBillingQueryDto {
    page = 1;
    limit = 10;
    search;
    get skip() {
        return ((this.page || 1) - 1) * (this.limit || 10);
    }
}
__decorate([
    IsOptional(),
    Type(() => Number),
    IsInt(),
    Min(1),
    __metadata("design:type", Number)
], AdminBillingQueryDto.prototype, "page", void 0);
__decorate([
    IsOptional(),
    Type(() => Number),
    IsInt(),
    Min(1),
    __metadata("design:type", Number)
], AdminBillingQueryDto.prototype, "limit", void 0);
__decorate([
    IsOptional(),
    IsString(),
    __metadata("design:type", String)
], AdminBillingQueryDto.prototype, "search", void 0);
export class AdminRefundDto {
    amount;
    reason;
}
__decorate([
    IsNumber(),
    Min(0.01),
    __metadata("design:type", Number)
], AdminRefundDto.prototype, "amount", void 0);
__decorate([
    IsOptional(),
    IsString(),
    __metadata("design:type", String)
], AdminRefundDto.prototype, "reason", void 0);
//# sourceMappingURL=admin-billing.dto.js.map