import { ExceptionFilter, Catch, ArgumentsHost, HttpStatus, Logger } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { Request, Response } from 'express';

@Catch(Prisma.PrismaClientKnownRequestError)
export class PrismaClientExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(PrismaClientExceptionFilter.name);

  catch(exception: Prisma.PrismaClientKnownRequestError, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();
    const requestId = request.id || request.headers['x-request-id'] || 'unknown';
    
    switch (exception.code) {
      case 'P2002': {
        const status = HttpStatus.CONFLICT;
        
        response.status(status).json({
          statusCode: status,
          code: 'UNIQUE_CONSTRAINT_VIOLATION',
          message: 'A unique constraint would be violated on the requested resource.',
          requestId,
        });
        break;
      }
      case 'P2025': {
        const status = HttpStatus.NOT_FOUND;
        
        response.status(status).json({
          statusCode: status,
          code: 'RESOURCE_NOT_FOUND',
          message: 'The requested resource was not found.',
          requestId,
        });
        break;
      }
      default:
        // default 500 error
        this.logger.error(`Prisma Error [${requestId}]: ${exception.message}`, exception.stack);
        response.status(HttpStatus.INTERNAL_SERVER_ERROR).json({
          statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
          code: 'DATABASE_ERROR',
          message: 'An unexpected database error occurred.',
          requestId,
        });
        break;
    }
  }
}
