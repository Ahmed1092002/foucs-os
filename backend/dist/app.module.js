"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppModule = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const health_module_1 = require("./health/health.module");
const prisma_module_1 = require("./prisma/prisma.module");
const auth_module_1 = require("./auth/auth.module");
const areas_module_1 = require("./learning-areas/areas.module");
const subjects_module_1 = require("./subjects/subjects.module");
const sessions_module_1 = require("./study-sessions/sessions.module");
const courses_module_1 = require("./courses/courses.module");
const daily_plans_module_1 = require("./daily-plans/daily-plans.module");
const daily_reviews_module_1 = require("./daily-reviews/daily-reviews.module");
const statistics_module_1 = require("./statistics/statistics.module");
const sync_module_1 = require("./sync/sync.module");
let AppModule = class AppModule {
};
exports.AppModule = AppModule;
exports.AppModule = AppModule = __decorate([
    (0, common_1.Module)({
        imports: [
            config_1.ConfigModule.forRoot({ isGlobal: true }),
            prisma_module_1.PrismaModule,
            health_module_1.HealthModule,
            auth_module_1.AuthModule,
            areas_module_1.AreasModule,
            subjects_module_1.SubjectsModule,
            sessions_module_1.SessionsModule,
            courses_module_1.CoursesModule,
            daily_plans_module_1.DailyPlansModule,
            daily_reviews_module_1.DailyReviewsModule,
            statistics_module_1.StatisticsModule,
            sync_module_1.SyncModule,
        ],
    })
], AppModule);
//# sourceMappingURL=app.module.js.map