import { Module } from '@nestjs/common';
import { DailyReviewsController } from './daily-reviews.controller';
import { DailyReviewsService } from './daily-reviews.service';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [AuthModule],
  controllers: [DailyReviewsController],
  providers: [DailyReviewsService],
  exports: [DailyReviewsService],
})
export class DailyReviewsModule {}