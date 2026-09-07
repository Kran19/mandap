import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();
    
    // The request ID injected by Pino or our middleware
    const requestId = request.id || request.headers['x-request-id'] || 'unknown';

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message = 'Internal server error';
    let code = 'INTERNAL_ERROR';

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const res = exception.getResponse();
      
      if (typeof res === 'object' && res !== null) {
        message = (res as any).message || exception.message;
        code = (res as any).error ? (res as any).error.toUpperCase().replace(/\s+/g, '_') : 'HTTP_ERROR';
      } else {
        message = exception.message;
      }
    } else {
      // Unhandled exception (e.g. TypeErrors)
      this.logger.error(`Unhandled Exception [${requestId}]: ${(exception as any)?.message}`, (exception as any)?.stack);
    }

    // Always return a sanitized response for 500s
    if (status === HttpStatus.INTERNAL_SERVER_ERROR) {
      message = 'An unexpected error occurred. Please contact support.';
      code = 'INTERNAL_SERVER_ERROR';
    }

    response.status(status).json({
      statusCode: status,
      code,
      message,
      requestId,
      timestamp: new Date().toISOString(),
    });
  }
}
