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
exports.ReviewDateParam = exports.UpsertReviewDto = void 0;
const class_transformer_1 = require("class-transformer");
const class_validator_1 = require("class-validator");
const swagger_1 = require("@nestjs/swagger");
class UpsertReviewDto {
    productivityRating;
    energyRating;
    focusRating;
    wentWell;
    blockedBy;
}
exports.UpsertReviewDto = UpsertReviewDto;
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: 4, minimum: 1, maximum: 5 }),
    (0, class_validator_1.IsOptional)(),
    (0, class_transformer_1.Type)(() => Number),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(1),
    (0, class_validator_1.Max)(5),
    __metadata("design:type", Number)
], UpsertReviewDto.prototype, "productivityRating", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: 3, minimum: 1, maximum: 5 }),
    (0, class_validator_1.IsOptional)(),
    (0, class_transformer_1.Type)(() => Number),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(1),
    (0, class_validator_1.Max)(5),
    __metadata("design:type", Number)
], UpsertReviewDto.prototype, "energyRating", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: 5, minimum: 1, maximum: 5 }),
    (0, class_validator_1.IsOptional)(),
    (0, class_transformer_1.Type)(() => Number),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(1),
    (0, class_validator_1.Max)(5),
    __metadata("design:type", Number)
], UpsertReviewDto.prototype, "focusRating", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: 'Completed React hooks deep dive', maxLength: 2000 }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MaxLength)(2000),
    __metadata("design:type", String)
], UpsertReviewDto.prototype, "wentWell", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: 'Blocked by missing docs', maxLength: 2000 }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MaxLength)(2000),
    __metadata("design:type", String)
], UpsertReviewDto.prototype, "blockedBy", void 0);
class ReviewDateParam {
    date;
}
exports.ReviewDateParam = ReviewDateParam;
__decorate([
    (0, swagger_1.ApiProperty)({ example: '2026-09-07', format: 'date' }),
    (0, class_validator_1.IsDateString)(),
    __metadata("design:type", String)
], ReviewDateParam.prototype, "date", void 0);
//# sourceMappingURL=review.dto.js.map