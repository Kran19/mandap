var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { IsEnum, IsOptional, IsString } from 'class-validator';
import { UserStatus } from '@prisma/client';
import { PaginationDto } from '../../common/dto/pagination.dto.js';
export class AdminUserQueryDto extends PaginationDto {
    status;
    search;
}
__decorate([
    IsOptional(),
    IsEnum(UserStatus),
    __metadata("design:type", String)
], AdminUserQueryDto.prototype, "status", void 0);
__decorate([
    IsOptional(),
    IsString(),
    __metadata("design:type", String)
], AdminUserQueryDto.prototype, "search", void 0);
export class AdminUpdateUserDto {
    status;
}
__decorate([
    IsOptional(),
    IsEnum(UserStatus),
    __metadata("design:type", String)
], AdminUpdateUserDto.prototype, "status", void 0);
//# sourceMappingURL=admin-users.dto.js.map