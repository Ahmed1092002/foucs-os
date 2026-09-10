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
Object.defineProperty(exports, "__esModule", { value: true });
exports.ReplacePlanDto = exports.PlanItemDto = void 0;
const class_transformer_1 = require("class-transformer");
const class_validator_1 = require("class-validator");
const swagger_1 = require("@nestjs/swagger");
class PlanItemDto {
    subjectId;
    startTime;
    durationSeconds;
    orderIndex;
}
exports.PlanItemDto = PlanItemDto;
__decorate([
    (0, swagger_1.ApiProperty)({ example: '550e8400-e29b-41d4-a716-446655440001', format: 'uuid' }),
    (0, class_validator_1.IsUUID)(),
    __metadata("design:type", String)
], PlanItemDto.prototype, "subjectId", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: '09:30', pattern: '^([01]\\d|2[0-3]):[0-5]\\d$' }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.Matches)(/^([01]\d|2[0-3]):[0-5]\d$/, { message: 'startTime must be HH:MM' }),
    __metadata("design:type", String)
], PlanItemDto.prototype, "startTime", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 3600, minimum: 60, maximum: 28800 }),
    (0, class_transformer_1.Type)(() => Number),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(60),
    (0, class_validator_1.Max)(60 * 60 * 8),
    __metadata("design:type", Number)
], PlanItemDto.prototype, "durationSeconds", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: 0, minimum: 0 }),
    (0, class_validator_1.IsOptional)(),
    (0, class_transformer_1.Type)(() => Number),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(0),
    __metadata("design:type", Number)
], PlanItemDto.prototype, "orderIndex", void 0);
class ReplacePlanDto {
    items;
}
exports.ReplacePlanDto = ReplacePlanDto;
__decorate([
    (0, swagger_1.ApiProperty)({ type: [PlanItemDto] }),
    (0, class_validator_1.IsArray)(),
    (0, class_validator_1.ArrayMinSize)(0),
    (0, class_validator_1.ValidateNested)({ each: true }),
    (0, class_transformer_1.Type)(() => PlanItemDto),
    __metadata("design:type", Array)
], ReplacePlanDto.prototype, "items", void 0);
//# sourceMappingURL=plan.dto.js.map