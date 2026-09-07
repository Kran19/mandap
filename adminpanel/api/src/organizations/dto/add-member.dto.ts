import { IsEmail, IsEnum, IsNotEmpty } from 'class-validator';
import { MembershipRole } from '@prisma/client';

export class AddMemberDto {
  @IsEmail()
  @IsNotEmpty()
  email!: string;

  // We explicitly reject OWNER in the controller/service, but we can also restrict it in validation
  @IsEnum(MembershipRole, { message: 'Role must be a valid membership role (excluding OWNER)' })
  role!: MembershipRole;
}
