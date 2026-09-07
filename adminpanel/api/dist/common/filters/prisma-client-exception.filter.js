var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var PrismaClientExceptionFilter_1;
import { Catch, HttpStatus, Logger } from '@nestjs/common';
import { Prisma } from '@prisma/client';
let PrismaClientExceptionFilter = PrismaClientExceptionFilter_1 = class PrismaClientExceptionFilter {
    logger = new Logger(PrismaClientExceptionFilter_1.name);
    catch(exception, host) {
        const ctx = host.switchToHttp();
        const response = ctx.getResponse();
        const request = ctx.getRequest();
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
};
PrismaClientExceptionFilter = PrismaClientExceptionFilter_1 = __decorate([
    Catch(Prisma.PrismaClientKnownRequestError)
], PrismaClientExceptionFilter);
export { PrismaClientExceptionFilter };
//# sourceMappingURL=prisma-client-exception.filter.js.map