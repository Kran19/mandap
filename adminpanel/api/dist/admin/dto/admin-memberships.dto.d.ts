import { MembershipRole } from '@prisma/client';
import { PaginationDto } from '../../common/dto/pagination.dto.js';
export declare class AdminMembershipQueryDto extends PaginationDto {
    role?: MembershipRole;
    userId?: string;
}
export declare class AdminAddMembershipDto {
    userId: string;
    role: MembershipRole;
}
export declare class AdminUpdateMembershipDto {
    role: MembershipRole;
}
