import { ExceptionFilter, ArgumentsHost } from '@nestjs/common';
import { Prisma } from '@prisma/client';
export declare class PrismaClientExceptionFilter implements ExceptionFilter {
    private readonly logger;
    catch(exception: Prisma.PrismaClientKnownRequestError, host: ArgumentsHost): void;
}
