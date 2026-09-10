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
exports.GoalResult = exports.SessionState = exports.CompleteSessionDto = exports.UpdateSessionDto = exports.CreateSessionDto = void 0;
const class_transformer_1 = require("class-transformer");
const class_validator_1 = require("class-validator");
const swagger_1 = require("@nestjs/swagger");
const STATES = ['running', 'paused', 'completed', 'cancelled'];
const GOAL_RESULTS = ['yes', 'partially', 'no'];
class CreateSessionDto {
    id;
    subjectId;
    topic;
    plannedDurationSeconds;
    startedAt;
    goalText;
}
exports.CreateSessionDto = CreateSessionDto;
__decorate([
    (0, swagger_1.ApiProperty)({ example: '550e8400-e29b-41d4-a716-446655440000', format: 'uuid' }),
    (0, class_validator_1.IsUUID)(),
    __metadata("design:type", String)
], CreateSessionDto.prototype, "id", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: '550e8400-e29b-41d4-a716-446655440001', format: 'uuid' }),
    (0, class_validator_1.IsUUID)(),
    __metadata("design:type", String)
], CreateSessionDto.prototype, "subjectId", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: 'useEffect deep dive', maxLength: 120 }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MaxLength)(120),
    __metadata("design:type", String)
], CreateSessionDto.prototype, "topic", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 3600, minimum: 60, maximum: 28800, description: 'Planned duration in seconds (1 min to 8 hours)' }),
    (0, class_transformer_1.Type)(() => Number),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(60),
    (0, class_validator_1.Max)(60 * 60 * 8),
    __metadata("design:type", Number)
], CreateSessionDto.prototype, "plannedDurationSeconds", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: '2026-09-07T10:00:00.000Z', format: 'date-time' }),
    (0, class_validator_1.IsDateString)(),
    __metadata("design:type", String)
], CreateSessionDto.prototype, "startedAt", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: "Understand when useEffect should and shouldn't be used", maxLength: 500 }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MaxLength)(500),
    __metadata("design:type", String)
], CreateSessionDto.prototype, "goalText", void 0);
class UpdateSessionDto {
    topic;
    goalText;
    state;
    pausedIntervalsSeconds;
    endedAt;
    actualDurationSeconds;
}
exports.UpdateSessionDto = UpdateSessionDto;
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: 'useEffect deep dive', maxLength: 120 }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MaxLength)(120),
    __metadata("design:type", String)
], UpdateSessionDto.prototype, "topic", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: "Understand when useEffect should and shouldn't be used", maxLength: 500 }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MaxLength)(500),
    __metadata("design:type", String)
], UpdateSessionDto.prototype, "goalText", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ enum: STATES }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsIn)([...STATES]),
    __metadata("design:type", Object)
], UpdateSessionDto.prototype, "state", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: 300, minimum: 0 }),
    (0, class_validator_1.IsOptional)(),
    (0, class_transformer_1.Type)(() => Number),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(0),
    __metadata("design:type", Number)
], UpdateSessionDto.prototype, "pausedIntervalsSeconds", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ format: 'date-time' }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsDateString)(),
    __metadata("design:type", String)
], UpdateSessionDto.prototype, "endedAt", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: 3300, minimum: 0 }),
    (0, class_validator_1.IsOptional)(),
    (0, class_transformer_1.Type)(() => Number),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(0),
    __metadata("design:type", Number)
], UpdateSessionDto.prototype, "actualDurationSeconds", void 0);
class CompleteSessionDto {
    actualDurationSeconds;
    pausedIntervalsSeconds;
    endedAt;
    goalResult;
    focusRating;
    energyRating;
    notes;
}
exports.CompleteSessionDto = CompleteSessionDto;
__decorate([
    (0, swagger_1.ApiProperty)({ example: 3300, minimum: 0 }),
    (0, class_transformer_1.Type)(() => Number),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(0),
    __metadata("design:type", Number)
], CompleteSessionDto.prototype, "actualDurationSeconds", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 300, minimum: 0 }),
    (0, class_transformer_1.Type)(() => Number),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(0),
    __metadata("design:type", Number)
], CompleteSessionDto.prototype, "pausedIntervalsSeconds", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: '2026-09-07T10:55:00.000Z', format: 'date-time' }),
    (0, class_validator_1.IsDateString)(),
    __metadata("design:type", String)
], CompleteSessionDto.prototype, "endedAt", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ enum: GOAL_RESULTS }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsIn)([...GOAL_RESULTS]),
    __metadata("design:type", Object)
], CompleteSessionDto.prototype, "goalResult", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: 4, minimum: 1, maximum: 5 }),
    (0, class_validator_1.IsOptional)(),
    (0, class_transformer_1.Type)(() => Number),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(1),
    (0, class_validator_1.Max)(5),
    __metadata("design:type", Number)
], CompleteSessionDto.prototype, "focusRating", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: 3, minimum: 1, maximum: 5 }),
    (0, class_validator_1.IsOptional)(),
    (0, class_transformer_1.Type)(() => Number),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(1),
    (0, class_validator_1.Max)(5),
    __metadata("design:type", Number)
], CompleteSessionDto.prototype, "energyRating", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: "Learned that useEffect should mainly synchronize with external systems.", maxLength: 2000 }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MaxLength)(2000),
    __metadata("design:type", String)
], CompleteSessionDto.prototype, "notes", void 0);
exports.SessionState = Object.freeze(STATES);
exports.GoalResult = Object.freeze(GOAL_RESULTS);
//# sourceMappingURL=session.dto.js.map