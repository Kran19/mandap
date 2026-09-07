import { IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateOrganizationDto {
  @IsString()
  @IsOptional()
  @IsNotEmpty()
  @MaxLength(100)
  name?: string;
}
