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
exports.StatisticsController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const jwt_auth_guard_1 = require("../auth/guards/jwt-auth.guard");
const current_user_decorator_1 = require("../common/decorators/current-user.decorator");
const statistics_service_1 = require("./statistics.service");
let StatisticsController = class StatisticsController {
    stats;
    constructor(stats) {
        this.stats = stats;
    }
    summary(user, range = 'week') {
        return this.stats.summary(user.id, range);
    }
    bySubject(user, range = 'week') {
        return this.stats.bySubject(user.id, range);
    }
    byDay(user, from, to) {
        return this.stats.byDay(user.id, from, to);
    }
    streak(user) {
        return this.stats.streak(user.id);
    }
};
exports.StatisticsController = StatisticsController;
__decorate([
    (0, common_1.Get)('summary'),
    (0, swagger_1.ApiOperation)({ summary: 'Get summary statistics for a time range' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Summary stats' }),
    (0, swagger_1.ApiResponse)({ status: 401, description: 'Unauthorized' }),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Query)('range')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], StatisticsController.prototype, "summary", null);
__decorate([
    (0, common_1.Get)('by-subject'),
    (0, swagger_1.ApiOperation)({ summary: 'Get study time grouped by subject' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Subject breakdown' }),
    (0, swagger_1.ApiResponse)({ status: 401, description: 'Unauthorized' }),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Query)('range')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], StatisticsController.prototype, "bySubject", null);
__decorate([
    (0, common_1.Get)('by-day'),
    (0, swagger_1.ApiOperation)({ summary: 'Get study time grouped by day' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Daily breakdown' }),
    (0, swagger_1.ApiResponse)({ status: 401, description: 'Unauthorized' }),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Query)('from')),
    __param(2, (0, common_1.Query)('to')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", void 0)
], StatisticsController.prototype, "byDay", null);
__decorate([
    (0, common_1.Get)('streak'),
    (0, swagger_1.ApiOperation)({ summary: 'Get current and longest learning streaks' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Streak data' }),
    (0, swagger_1.ApiResponse)({ status: 401, description: 'Unauthorized' }),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], StatisticsController.prototype, "streak", null);
exports.StatisticsController = StatisticsController = __decorate([
    (0, swagger_1.ApiTags)('statistics'),
    (0, swagger_1.ApiBearerAuth)(),
    (0, common_1.Controller)('stats'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __metadata("design:paramtypes", [statistics_service_1.StatisticsService])
], StatisticsController);
//# sourceMappingURL=statistics.controller.js.map