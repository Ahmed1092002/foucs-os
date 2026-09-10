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
exports.UpdateAreaDto = exports.CreateAreaDto = void 0;
const class_validator_1 = require("class-validator");
const swagger_1 = require("@nestjs/swagger");
class CreateAreaDto {
    name;
    color;
    icon;
}
exports.CreateAreaDto = CreateAreaDto;
__decorate([
    (0, swagger_1.ApiProperty)({ example: 'Frontend', minLength: 1, maxLength: 64 }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MinLength)(1),
    (0, class_validator_1.MaxLength)(64),
    __metadata("design:type", String)
], CreateAreaDto.prototype, "name", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: '#5B8DEF', pattern: '^#[0-9A-Fa-f]{6}$' }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.Matches)(/^#[0-9A-Fa-f]{6}$/, { message: 'color must be a 6-digit hex like #5B8DEF' }),
    __metadata("design:type", String)
], CreateAreaDto.prototype, "color", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: 'code', maxLength: 32 }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MaxLength)(32),
    __metadata("design:type", String)
], CreateAreaDto.prototype, "icon", void 0);
class UpdateAreaDto {
    name;
    color;
    icon;
    archived;
}
exports.UpdateAreaDto = UpdateAreaDto;
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ minLength: 1, maxLength: 64 }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MinLength)(1),
    (0, class_validator_1.MaxLength)(64),
    __metadata("design:type", String)
], UpdateAreaDto.prototype, "name", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ pattern: '^#[0-9A-Fa-f]{6}$' }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.Matches)(/^#[0-9A-Fa-f]{6}$/),
    __metadata("design:type", String)
], UpdateAreaDto.prototype, "color", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ maxLength: 32 }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MaxLength)(32),
    __metadata("design:type", String)
], UpdateAreaDto.prototype, "icon", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: false }),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", Boolean)
], UpdateAreaDto.prototype, "archived", void 0);
//# sourceMappingURL=area.dto.js.map