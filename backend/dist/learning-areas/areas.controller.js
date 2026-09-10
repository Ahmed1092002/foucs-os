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
exports.AreasController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const jwt_auth_guard_1 = require("../auth/guards/jwt-auth.guard");
const current_user_decorator_1 = require("../common/decorators/current-user.decorator");
const areas_service_1 = require("./areas.service");
const area_dto_1 = require("./dto/area.dto");
let AreasController = class AreasController {
    areas;
    constructor(areas) {
        this.areas = areas;
    }
    list(user, includeArchived) {
        const flag = includeArchived === 'true' || includeArchived === '1';
        return this.areas.list(user.id, flag);
    }
    getOne(user, id) {
        return this.areas.getOne(user.id, id);
    }
    create(user, dto) {
        return this.areas.create(user.id, dto);
    }
    update(user, id, dto) {
        return this.areas.update(user.id, id, dto);
    }
    async remove(user, id) {
        await this.areas.softDelete(user.id, id);
    }
};
exports.AreasController = AreasController;
__decorate([
    (0, common_1.Get)(),
    (0, swagger_1.ApiOperation)({ summary: 'List all learning areas' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'List of areas' }),
    (0, swagger_1.ApiResponse)({ status: 401, description: 'Unauthorized' }),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Query)('includeArchived')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], AreasController.prototype, "list", null);
__decorate([
    (0, common_1.Get)(':id'),
    (0, swagger_1.ApiOperation)({ summary: 'Get a single learning area by ID' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Area details' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'Area not found' }),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], AreasController.prototype, "getOne", null);
__decorate([
    (0, common_1.Post)(),
    (0, swagger_1.ApiOperation)({ summary: 'Create a new learning area' }),
    (0, swagger_1.ApiResponse)({ status: 201, description: 'Area created' }),
    (0, swagger_1.ApiResponse)({ status: 400, description: 'Validation error' }),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, area_dto_1.CreateAreaDto]),
    __metadata("design:returntype", void 0)
], AreasController.prototype, "create", null);
__decorate([
    (0, common_1.Patch)(':id'),
    (0, swagger_1.ApiOperation)({ summary: 'Update a learning area' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Area updated' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'Area not found' }),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, area_dto_1.UpdateAreaDto]),
    __metadata("design:returntype", void 0)
], AreasController.prototype, "update", null);
__decorate([
    (0, common_1.Delete)(':id'),
    (0, common_1.HttpCode)(common_1.HttpStatus.NO_CONTENT),
    (0, swagger_1.ApiOperation)({ summary: 'Soft delete a learning area' }),
    (0, swagger_1.ApiResponse)({ status: 204, description: 'Area deleted' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'Area not found' }),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], AreasController.prototype, "remove", null);
exports.AreasController = AreasController = __decorate([
    (0, swagger_1.ApiTags)('areas'),
    (0, swagger_1.ApiBearerAuth)(),
    (0, common_1.Controller)('areas'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __metadata("design:paramtypes", [areas_service_1.AreasService])
], AreasController);
//# sourceMappingURL=areas.controller.js.map