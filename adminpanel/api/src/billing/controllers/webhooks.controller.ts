import { Controller, Post, Headers, Req, BadRequestException } from '@nestjs/common';
import { WebhooksService } from '../services/webhooks.service.js';
import { Request } from 'express';

interface RequestWithRawBody extends Request {
  rawBody?: Buffer;
}

@Controller('billing/webhooks')
export class WebhooksController {
  constructor(private readonly webhooksService: WebhooksService) {}

  @Post('razorpay')
  async handleRazorpayWebhook(
    @Headers('x-razorpay-signature') signature: string,
    @Req() req: RequestWithRawBody
  ) {
    if (!signature) {
      throw new BadRequestException('Missing signature');
    }

    if (!req.rawBody) {
      throw new BadRequestException('Raw body not preserved');
    }

    // Try to parse the event id and type from the standard body, or fall back to parsing raw string.
    let providerEventId: string;
    let eventType: string;

    try {
      const payload = JSON.parse(req.rawBody.toString('utf8'));
      providerEventId = payload['x-razorpay-event-id'] || payload['event_id'] || req.headers['x-razorpay-event-id'] || `req_${Date.now()}`;
      eventType = payload['event'];
      if (!eventType) throw new Error();
    } catch {
      throw new BadRequestException('Invalid payload or missing event type');
    }

    await this.webhooksService.processWebhook(
      signature,
      req.rawBody,
      providerEventId as string,
      eventType
    );

    return { status: 'ok' };
  }
}
