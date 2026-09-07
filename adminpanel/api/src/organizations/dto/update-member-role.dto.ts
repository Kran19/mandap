import { IsEnum, IsNotEmpty } from 'class-validator';
import { MembershipRole } from '@prisma/client';

export class UpdateMemberRoleDto {
  @IsEnum(MembershipRole, { message: 'Role must be a valid membership role' })
  @IsNotEmpty()
  role!: MembershipRole;
}
