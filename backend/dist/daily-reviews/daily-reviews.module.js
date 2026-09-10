"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.DailyReviewsModule = void 0;
const common_1 = require("@nestjs/common");
const daily_reviews_controller_1 = require("./daily-reviews.controller");
const daily_reviews_service_1 = require("./daily-reviews.service");
const auth_module_1 = require("../auth/auth.module");
let DailyReviewsModule = class DailyReviewsModule {
};
exports.DailyReviewsModule = DailyReviewsModule;
exports.DailyReviewsModule = DailyReviewsModule = __decorate([
    (0, common_1.Module)({
        imports: [auth_module_1.AuthModule],
        controllers: [daily_reviews_controller_1.DailyReviewsController],
        providers: [daily_reviews_service_1.DailyReviewsService],
        exports: [daily_reviews_service_1.DailyReviewsService],
    })
], DailyReviewsModule);
//# sourceMappingURL=daily-reviews.module.js.map