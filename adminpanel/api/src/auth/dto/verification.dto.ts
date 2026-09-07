import { IsString, IsNotEmpty } from 'class-validator';

export class VerifyEmailDto {
  @IsString()
  @IsNotEmpty()
  token!: string;
}

export class SendOtpDto {
  @IsString()
  @IsNotEmpty()
  phone!: string;
}

export class VerifyOtpDto {
  @IsString()
  @IsNotEmpty()
  phone!: string;

  @IsString()
  @IsNotEmpty()
  code!: string;
}

export class VerifyIdentityDto {
  @IsString()
  @IsNotEmpty()
  identityReference!: string;
}
