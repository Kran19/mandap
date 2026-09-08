import { Module, Global, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Redis } from 'ioredis';

export const REDIS_CLIENT = 'REDIS_CLIENT';

@Global()
@Module({
  providers: [
    {
      provide: REDIS_CLIENT,
      useFactory: (configService: ConfigService) => {
        const logger = new Logger('RedisClient');
        const redisUrl = configService.get<string>('REDIS_URL', 'redis://localhost:6379');
        const client = new Redis(redisUrl, {
          maxRetriesPerRequest: 3,
          retryStrategy(times) {
            return Math.min(times * 100, 3000);
          },
          lazyConnect: false,
        });

        client.on('error', (err) => {
          logger.warn(`Redis connection error (${redisUrl}): ${err.message}`);
        });

        client.on('connect', () => {
          logger.log(`Connected to Redis at ${redisUrl}`);
        });

        return client;
      },
      inject: [ConfigService],
    },
  ],
  exports: [REDIS_CLIENT],
})
export class RedisModule {}
