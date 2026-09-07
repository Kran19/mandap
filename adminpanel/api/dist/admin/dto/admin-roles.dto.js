var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { IsBoolean, IsOptional, IsString, IsArray } from 'class-validator';
import { PaginationDto } from '../../common/dto/pagination.dto.js';
export class AdminRoleQueryDto extends PaginationDto {
    search;
}
__decorate([
    IsOptional(),
    IsString(),
    __metadata("design:type", String)
], AdminRoleQueryDto.prototype, "search", void 0);
export class AdminCreateRoleDto {
    name;
    description;
    permissions;
}
__decorate([
    IsString(),
    __metadata("design:type", String)
], AdminCreateRoleDto.prototype, "name", void 0);
__decorate([
    IsOptional(),
    IsString(),
    __metadata("design:type", String)
], AdminCreateRoleDto.prototype, "description", void 0);
__decorate([
    IsArray(),
    IsString({ each: true }),
    __metadata("design:type", Array)
], AdminCreateRoleDto.prototype, "permissions", void 0);
export class AdminUpdateRoleDto {
    description;
    isActive;
    permissions;
}
__decorate([
    IsOptional(),
    IsString(),
    __metadata("design:type", String)
], AdminUpdateRoleDto.prototype, "description", void 0);
__decorate([
    IsOptional(),
    IsBoolean(),
    __metadata("design:type", Boolean)
], AdminUpdateRoleDto.prototype, "isActive", void 0);
__decorate([
    IsOptional(),
    IsArray(),
    IsString({ each: true }),
    __metadata("design:type", Array)
], AdminUpdateRoleDto.prototype, "permissions", void 0);
//# sourceMappingURL=admin-roles.dto.js.map