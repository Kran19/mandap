import { IsNotEmpty, IsString } from 'class-validator';

export class VerifyLoginOtpDto {
  @IsString()
  @IsNotEmpty()
  challengeId!: string;

  @IsString()
  @IsNotEmpty()
  otp!: string;
}
