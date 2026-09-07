import { Controller, Get, VERSION_NEUTRAL } from '@nestjs/common';

@Controller({
  version: VERSION_NEUTRAL,
})
export class AppController {
  @Get()
  getHello() {
    return {
      service: 'MANDAP API',
      status: 'online',
      phase: 10,
      timestamp: new Date().toISOString(),
    };
  }
}
