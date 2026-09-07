var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var AllExceptionsFilter_1;
import { Catch, HttpException, HttpStatus, Logger, } from '@nestjs/common';
let AllExceptionsFilter = AllExceptionsFilter_1 = class AllExceptionsFilter {
    logger = new Logger(AllExceptionsFilter_1.name);
    catch(exception, host) {
        const ctx = host.switchToHttp();
        const response = ctx.getResponse();
        const request = ctx.getRequest();
        const requestId = request.id || request.headers['x-request-id'] || 'unknown';
        let status = HttpStatus.INTERNAL_SERVER_ERROR;
        let message = 'Internal server error';
        let code = 'INTERNAL_ERROR';
        if (exception instanceof HttpException) {
            status = exception.getStatus();
            const res = exception.getResponse();
            if (typeof res === 'object' && res !== null) {
                message = res.message || exception.message;
                code = res.error ? res.error.toUpperCase().replace(/\s+/g, '_') : 'HTTP_ERROR';
            }
            else {
                message = exception.message;
            }
        }
        else {
            this.logger.error(`Unhandled Exception [${requestId}]: ${exception?.message}`, exception?.stack);
        }
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
};
AllExceptionsFilter = AllExceptionsFilter_1 = __decorate([
    Catch()
], AllExceptionsFilter);
export { AllExceptionsFilter };
//# sourceMappingURL=all-exceptions.filter.js.map