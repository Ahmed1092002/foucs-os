import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { HealthModule } from './health/health.module';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { AreasModule } from './learning-areas/areas.module';
import { SubjectsModule } from './subjects/subjects.module';
import { SessionsModule } from './study-sessions/sessions.module';
import { CoursesModule } from './courses/courses.module';
import { DailyPlansModule } from './daily-plans/daily-plans.module';
import { DailyReviewsModule } from './daily-reviews/daily-reviews.module';
import { StatisticsModule } from './statistics/statistics.module';
import { SyncModule } from './sync/sync.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    HealthModule,
    AuthModule,
    AreasModule,
    SubjectsModule,
    SessionsModule,
    CoursesModule,
    DailyPlansModule,
    DailyReviewsModule,
    StatisticsModule,
    SyncModule,
  ],
})
export class AppModule {}