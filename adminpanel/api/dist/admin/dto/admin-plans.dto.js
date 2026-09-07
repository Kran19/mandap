var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { IsOptional, IsString, IsNumber, IsBoolean, IsArray, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { PaginationDto } from '../../common/dto/pagination.dto.js';
export class AdminPlanQueryDto extends PaginationDto {
    search;
    status;
}
__decorate([
    IsOptional(),
    IsString(),
    __metadata("design:type", String)
], AdminPlanQueryDto.prototype, "search", void 0);
__decorate([
    IsOptional(),
    IsString(),
    __metadata("design:type", String)
], AdminPlanQueryDto.prototype, "status", void 0);
export class AdminPlanFeatureDto {
    featureKey;
    enabled;
}
__decorate([
    IsString(),
    __metadata("design:type", String)
], AdminPlanFeatureDto.prototype, "featureKey", void 0);
__decorate([
    IsOptional(),
    IsBoolean(),
    __metadata("design:type", Boolean)
], AdminPlanFeatureDto.prototype, "enabled", void 0);
export class AdminPlanLimitDto {
    key;
    limit;
}
__decorate([
    IsString(),
    __metadata("design:type", String)
], AdminPlanLimitDto.prototype, "key", void 0);
__decorate([
    IsNumber(),
    __metadata("design:type", Number)
], AdminPlanLimitDto.prototype, "limit", void 0);
export class AdminCreatePlanDto {
    name;
    slug;
    description;
    monthlyPrice;
    yearlyPrice;
    currency;
    status;
    features;
    limits;
}
__decorate([
    IsString(),
    __metadata("design:type", String)
], AdminCreatePlanDto.prototype, "name", void 0);
__decorate([
    IsString(),
    __metadata("design:type", String)
], AdminCreatePlanDto.prototype, "slug", void 0);
__decorate([
    IsOptional(),
    IsString(),
    __metadata("design:type", String)
], AdminCreatePlanDto.prototype, "description", void 0);
__decorate([
    IsOptional(),
    IsNumber(),
    __metadata("design:type", Number)
], AdminCreatePlanDto.prototype, "monthlyPrice", void 0);
__decorate([
    IsOptional(),
    IsNumber(),
    __metadata("design:type", Number)
], AdminCreatePlanDto.prototype, "yearlyPrice", void 0);
__decorate([
    IsOptional(),
    IsString(),
    __metadata("design:type", String)
], AdminCreatePlanDto.prototype, "currency", void 0);
__decorate([
    IsOptional(),
    IsString(),
    __metadata("design:type", String)
], AdminCreatePlanDto.prototype, "status", void 0);
__decorate([
    IsOptional(),
    IsArray(),
    ValidateNested({ each: true }),
    Type(() => AdminPlanFeatureDto),
    __metadata("design:type", Array)
], AdminCreatePlanDto.prototype, "features", void 0);
__decorate([
    IsOptional(),
    IsArray(),
    ValidateNested({ each: true }),
    Type(() => AdminPlanLimitDto),
    __metadata("design:type", Array)
], AdminCreatePlanDto.prototype, "limits", void 0);
export class AdminUpdatePlanDto {
    name;
    description;
    monthlyPrice;
    yearlyPrice;
    currency;
    status;
    features;
    limits;
}
__decorate([
    IsOptional(),
    IsString(),
    __metadata("design:type", String)
], AdminUpdatePlanDto.prototype, "name", void 0);
__decorate([
    IsOptional(),
    IsString(),
    __metadata("design:type", String)
], AdminUpdatePlanDto.prototype, "description", void 0);
__decorate([
    IsOptional(),
    IsNumber(),
    __metadata("design:type", Number)
], AdminUpdatePlanDto.prototype, "monthlyPrice", void 0);
__decorate([
    IsOptional(),
    IsNumber(),
    __metadata("design:type", Number)
], AdminUpdatePlanDto.prototype, "yearlyPrice", void 0);
__decorate([
    IsOptional(),
    IsString(),
    __metadata("design:type", String)
], AdminUpdatePlanDto.prototype, "currency", void 0);
__decorate([
    IsOptional(),
    IsString(),
    __metadata("design:type", String)
], AdminUpdatePlanDto.prototype, "status", void 0);
__decorate([
    IsOptional(),
    IsArray(),
    ValidateNested({ each: true }),
    Type(() => AdminPlanFeatureDto),
    __metadata("design:type", Array)
], AdminUpdatePlanDto.prototype, "features", void 0);
__decorate([
    IsOptional(),
    IsArray(),
    ValidateNested({ each: true }),
    Type(() => AdminPlanLimitDto),
    __metadata("design:type", Array)
], AdminUpdatePlanDto.prototype, "limits", void 0);
//# sourceMappingURL=admin-plans.dto.js.map