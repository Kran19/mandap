export interface SmsSendResult {
  success: boolean;
  messageId?: string;
  gatewayResponse?: any;
  statusSummary: string;
}

export interface SmsProvider {
  sendSms(phone: string, message: string): Promise<boolean>;
  sendOtpSms?(phone: string, otp: string, candidateName?: string): Promise<SmsSendResult>;
}
