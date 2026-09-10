import { Module } from '@nestjs/common';
import {
  CoursesController,
  SubjectProgressController,
} from './courses.controller';
import { CoursesService } from './courses.service';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [AuthModule],
  controllers: [CoursesController, SubjectProgressController],
  providers: [CoursesService],
  exports: [CoursesService],
})
export class CoursesModule {}