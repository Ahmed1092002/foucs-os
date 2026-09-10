"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.DailyReviewsController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const jwt_auth_guard_1 = require("../auth/guards/jwt-auth.guard");
const current_user_decorator_1 = require("../common/decorators/current-user.decorator");
const daily_reviews_service_1 = require("./daily-reviews.service");
const review_dto_1 = require("./dto/review.dto");
let DailyReviewsController = class DailyReviewsController {
    reviews;
    constructor(reviews) {
        this.reviews = reviews;
    }
    list(user, from, to) {
        return this.reviews.list(user.id, from, to);
    }
    getForDate(user, date) {
        return this.reviews.getForDate(user.id, date);
    }
    upsert(user, date, dto) {
        return this.reviews.upsert(user.id, date, dto);
    }
};
exports.DailyReviewsController = DailyReviewsController;
__decorate([
    (0, common_1.Get)(),
    (0, swagger_1.ApiOperation)({ summary: 'List daily reviews in a date range' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'List of daily reviews' }),
    (0, swagger_1.ApiResponse)({ status: 401, description: 'Unauthorized' }),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Query)('from')),
    __param(2, (0, common_1.Query)('to')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", void 0)
], DailyReviewsController.prototype, "list", null);
__decorate([
    (0, common_1.Get)(':date'),
    (0, swagger_1.ApiOperation)({ summary: 'Get daily review for a specific date' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Daily review details' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'Review not found' }),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)('date')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], DailyReviewsController.prototype, "getForDate", null);
__decorate([
    (0, common_1.Put)(':date'),
    (0, swagger_1.ApiOperation)({ summary: 'Create or update daily review for a date' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Review created/updated' }),
    (0, swagger_1.ApiResponse)({ status: 400, description: 'Validation error' }),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)('date')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, review_dto_1.UpsertReviewDto]),
    __metadata("design:returntype", void 0)
], DailyReviewsController.prototype, "upsert", null);
exports.DailyReviewsController = DailyReviewsController = __decorate([
    (0, swagger_1.ApiTags)('reviews'),
    (0, swagger_1.ApiBearerAuth)(),
    (0, common_1.Controller)('reviews'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __metadata("design:paramtypes", [daily_reviews_service_1.DailyReviewsService])
], DailyReviewsController);
//# sourceMappingURL=daily-reviews.controller.js.map