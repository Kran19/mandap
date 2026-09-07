import { UserStatus } from '@prisma/client';
import { PaginationDto } from '../../common/dto/pagination.dto.js';
export declare class AdminUserQueryDto extends PaginationDto {
    status?: UserStatus;
    search?: string;
}
export declare class AdminUpdateUserDto {
    status?: UserStatus;
}
