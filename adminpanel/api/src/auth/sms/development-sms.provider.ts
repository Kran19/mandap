import { Injectable, Logger } from '@nestjs/common';
import { SmsProvider } from './sms.provider.js';

@Injectable()
export class DevelopmentSmsProvider implements SmsProvider {
  private readonly logger = new Logger(DevelopmentSmsProvider.name);

  async sendSms(phone: string, message: string): Promise<boolean> {
    this.logger.log(`[Development SMS] To: ${phone} | Message: ${message}`);
    // In development, we simulate success
    return true;
  }
}
