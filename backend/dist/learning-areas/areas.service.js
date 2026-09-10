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
exports.AreasService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let AreasService = class AreasService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    list(userId, includeArchived = false) {
        return this.prisma.learningArea.findMany({
            where: { userId, ...(includeArchived ? {} : { archivedAt: null }) },
            orderBy: { createdAt: 'asc' },
        });
    }
    async getOne(userId, id) {
        const area = await this.prisma.learningArea.findFirst({ where: { id, userId } });
        if (!area)
            throw new common_1.NotFoundException('Area not found');
        return area;
    }
    create(userId, dto) {
        return this.prisma.learningArea.create({
            data: { userId, name: dto.name, color: dto.color, icon: dto.icon },
        });
    }
    async update(userId, id, dto) {
        await this.getOne(userId, id);
        return this.prisma.learningArea.update({
            where: { id },
            data: {
                ...(dto.name !== undefined ? { name: dto.name } : {}),
                ...(dto.color !== undefined ? { color: dto.color } : {}),
                ...(dto.icon !== undefined ? { icon: dto.icon } : {}),
                ...(dto.archived !== undefined
                    ? { archivedAt: dto.archived ? new Date() : null }
                    : {}),
            },
        });
    }
    async softDelete(userId, id) {
        await this.getOne(userId, id);
        await this.prisma.learningArea.update({
            where: { id },
            data: { archivedAt: new Date() },
        });
    }
};
exports.AreasService = AreasService;
exports.AreasService = AreasService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], AreasService);
//# sourceMappingURL=areas.service.js.map