import { Injectable, Logger } from '@nestjs/common';
import { SmsProvider, SmsSendResult } from './sms.provider.js';

@Injectable()
export class DltSmsProvider implements SmsProvider {
  private readonly logger = new Logger(DltSmsProvider.name);

  private readonly uri = process.env.DLT_GATEWAY_URL || 'https://allsmssolution.in/sms-panel/api/http/index.php';
  private readonly username = process.env.DLT_USERNAME || 'EMPEROR';
  private readonly apikey = process.env.DLT_APIKEY || '62CEF-9A446';
  private readonly senderId = process.env.DLT_SENDER_ID || 'TXXTOO';
  private readonly templateId = process.env.DLT_TEMPLATE_ID || '1607100000000313742';
  private readonly entityId = process.env.DLT_ENTITY_ID || '1401805350000060162';
  private readonly route = process.env.DLT_ROUTE || 'TRANS';

  /**
   * Format the verified DLT Template message:
   * Dear {#var#} Your OTP for verification is {#var#}. Please enter this code to complete the process.
   * Regards {#var#}
   * TEXT2
   */
  buildOtpMessage(candidateName: string, otp: string, brand = 'MANDAP'): string {
    const name = candidateName?.trim() || 'Candidate';
    return `Dear ${name} Your OTP for verification is ${otp}. Please enter this code to complete the process.\nRegards ${brand}\nTEXT2`;
  }

  /**
   * Cleans recipient phone number to valid digits for the gateway.
   */
  cleanPhone(phone: string): string {
    let cleaned = phone.replace(/[^0-9]/g, '');
    // If 12 digits starting with 91, gateway supports both 10-digit and 91-prefixed
    if (cleaned.length === 12 && cleaned.startsWith('91')) {
      // standard 10 digit or keep as is
      cleaned = cleaned.substring(2);
    }
    return cleaned;
  }

  async sendOtpSms(phone: string, otp: string, candidateName?: string): Promise<SmsSendResult> {
    const cleanNumber = this.cleanPhone(phone);
    const message = this.buildOtpMessage(candidateName || 'Candidate', otp);

    const postData = new URLSearchParams({
      username: this.username,
      apikey: this.apikey,
      apirequest: 'Text',
      sender: this.senderId,
      route: this.route,
      format: 'JSON',
      message: message,
      mobile: cleanNumber,
      TemplateID: this.templateId,
      EntityID: this.entityId,
      PE_ID: this.entityId,
    });

    this.logger.log(`[DLT SMS] Dispatching to ${cleanNumber} with template ${this.templateId}`);

    try {
      const response = await fetch(this.uri, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: postData.toString(),
      });

      const rawText = await response.text();
      let parsed: any = null;
      let isSuccess = false;
      let messageId: string | undefined = undefined;
      let statusSummary = 'Response received';

      try {
        parsed = JSON.parse(rawText);
        if (parsed) {
          if (parsed['message-id']) {
            messageId = Array.isArray(parsed['message-id'])
              ? parsed['message-id'].join(', ')
              : String(parsed['message-id']);
          } else if (parsed.msgid) {
            messageId = String(parsed.msgid);
          }

          const statusField = String(parsed.status || parsed.status_code || parsed.response || '').toLowerCase();
          if (['success', 'queued', 'submitted', '1', '200', 'ok', 'sent'].includes(statusField)) {
            isSuccess = true;
            statusSummary = parsed.message || 'Queued / Sent Successfully';
          } else if (['error', 'failed', 'fail', '0'].includes(statusField)) {
            statusSummary = parsed.message || parsed.desc || parsed.error || 'Gateway returned failure';
          }
        }
      } catch {
        // Plain text response check
        if (/success|msgid|submitted/i.test(rawText)) {
          isSuccess = true;
          statusSummary = 'Success / Message ID Found';
        } else if (/err|invalid|fail/i.test(rawText)) {
          statusSummary = `Gateway Error: ${rawText.substring(0, 100)}`;
        }
      }

      // If HTTP ok and status looks valid
      if (response.ok && (isSuccess || messageId)) {
        isSuccess = true;
      }

      this.logger.log(`[DLT SMS Result] Phone: ${cleanNumber} | Success: ${isSuccess} | MsgId: ${messageId} | Status: ${statusSummary}`);

      return {
        success: isSuccess,
        messageId,
        gatewayResponse: parsed || rawText,
        statusSummary,
      };
    } catch (error: any) {
      this.logger.error(`[DLT SMS Error] Failed to send SMS: ${error?.message || error}`);
      return {
        success: false,
        statusSummary: `Connection Error: ${error?.message || error}`,
      };
    }
  }

  async sendSms(phone: string, message: string): Promise<boolean> {
    const cleanNumber = this.cleanPhone(phone);
    const postData = new URLSearchParams({
      username: this.username,
      apikey: this.apikey,
      apirequest: 'Text',
      sender: this.senderId,
      route: this.route,
      format: 'JSON',
      message: message,
      mobile: cleanNumber,
      TemplateID: this.templateId,
      EntityID: this.entityId,
      PE_ID: this.entityId,
    });

    try {
      const response = await fetch(this.uri, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: postData.toString(),
      });

      return response.ok;
    } catch (err) {
      this.logger.error(`sendSms error: ${err}`);
      return false;
    }
  }
}
