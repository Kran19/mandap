import { NestFactory } from '@nestjs/core';
import { ValidationPipe, VersioningType } from '@nestjs/common';
import { AppModule } from './app.module.js';
import { Logger } from 'nestjs-pino';
import helmet from 'helmet';
import * as express from 'express';
async function bootstrap() {
    const app = await NestFactory.create(AppModule, { bufferLogs: true, rawBody: true });
    app.useLogger(app.get(Logger));
    app.enableShutdownHooks();
    app.setGlobalPrefix('api', {
        exclude: ['/'],
    });
    app.enableVersioning({
        type: VersioningType.URI,
        defaultVersion: '1',
    });
    app.use(helmet());
    app.useGlobalPipes(new ValidationPipe({
        whitelist: true,
        transform: true,
        forbidNonWhitelisted: true,
    }));
    app.use(express.json({ limit: '6mb' }));
    app.use(express.urlencoded({ limit: '6mb', extended: true }));
    app.enableCors({
        origin: true,
        credentials: true,
    });
    await app.listen(process.env.PORT ?? 3001, '0.0.0.0');
}
bootstrap();
//# sourceMappingURL=main.js.map