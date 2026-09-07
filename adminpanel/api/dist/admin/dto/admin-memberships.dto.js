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
import { MembershipRole } from '@prisma/client';
import { PaginationDto } from '../../common/dto/pagination.dto.js';
export class AdminMembershipQueryDto extends PaginationDto {
    role;
    userId;
}
__decorate([
    IsOptional(),
    IsEnum(MembershipRole),
    __metadata("design:type", String)
], AdminMembershipQueryDto.prototype, "role", void 0);
__decorate([
    IsOptional(),
    IsString(),
    __metadata("design:type", String)
], AdminMembershipQueryDto.prototype, "userId", void 0);
export class AdminAddMembershipDto {
    userId;
    role;
}
__decorate([
    IsString(),
    __metadata("design:type", String)
], AdminAddMembershipDto.prototype, "userId", void 0);
__decorate([
    IsEnum(MembershipRole),
    __metadata("design:type", String)
], AdminAddMembershipDto.prototype, "role", void 0);
export class AdminUpdateMembershipDto {
    role;
}
__decorate([
    IsEnum(MembershipRole),
    __metadata("design:type", String)
], AdminUpdateMembershipDto.prototype, "role", void 0);
//# sourceMappingURL=admin-memberships.dto.js.map