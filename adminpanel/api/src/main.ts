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

  // Global Prefix & Versioning
  app.setGlobalPrefix('api', {
    exclude: ['/'],
  });
  app.enableVersioning({
    type: VersioningType.URI,
    defaultVersion: '1',
  });

  // Security Headers
  app.use(helmet());

  // Global Validation Pipe
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,
    transform: true,
    forbidNonWhitelisted: true,
  }));

  // Payload Limits
  app.use(express.json({ limit: '6mb' }));
  app.use(express.urlencoded({ limit: '6mb', extended: true }));

  // CORS Configuration
  app.enableCors({
    origin: true,
    credentials: true,
  });

  await app.listen(process.env.PORT ?? 3001, '0.0.0.0');
}
bootstrap();
