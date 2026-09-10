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
exports.SubjectProgressController = exports.CoursesController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const jwt_auth_guard_1 = require("../auth/guards/jwt-auth.guard");
const current_user_decorator_1 = require("../common/decorators/current-user.decorator");
const courses_service_1 = require("./courses.service");
const course_dto_1 = require("./dto/course.dto");
let CoursesController = class CoursesController {
    courses;
    constructor(courses) {
        this.courses = courses;
    }
    list(user, subjectId) {
        return this.courses.list(user.id, subjectId);
    }
    getOne(user, id) {
        return this.courses.getOne(user.id, id);
    }
    create(user, dto) {
        return this.courses.create(user.id, dto);
    }
    update(user, id, dto) {
        return this.courses.update(user.id, id, dto);
    }
    async remove(user, id) {
        await this.courses.remove(user.id, id);
    }
    listModules(user, courseId) {
        return this.courses.listModules(user.id, courseId);
    }
    addModule(user, courseId, dto) {
        return this.courses.addModule(user.id, courseId, dto);
    }
    updateModule(user, courseId, moduleId, dto) {
        return this.courses.updateModule(user.id, courseId, moduleId, dto);
    }
    async removeModule(user, courseId, moduleId) {
        await this.courses.removeModule(user.id, courseId, moduleId);
    }
    listLessons(user, moduleId) {
        return this.courses.listLessons(user.id, moduleId);
    }
    addLesson(user, moduleId, dto) {
        return this.courses.addLesson(user.id, moduleId, dto);
    }
    updateLesson(user, moduleId, lessonId, dto) {
        return this.courses.updateLesson(user.id, moduleId, lessonId, dto);
    }
    async removeLesson(user, moduleId, lessonId) {
        await this.courses.removeLesson(user.id, moduleId, lessonId);
    }
};
exports.CoursesController = CoursesController;
__decorate([
    (0, common_1.Get)(),
    (0, swagger_1.ApiOperation)({ summary: 'List all courses' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'List of courses' }),
    (0, swagger_1.ApiResponse)({ status: 401, description: 'Unauthorized' }),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Query)('subjectId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], CoursesController.prototype, "list", null);
__decorate([
    (0, common_1.Get)(':id'),
    (0, swagger_1.ApiOperation)({ summary: 'Get a single course by ID' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Course details with modules and lessons' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'Course not found' }),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], CoursesController.prototype, "getOne", null);
__decorate([
    (0, common_1.Post)(),
    (0, swagger_1.ApiOperation)({ summary: 'Create a new course' }),
    (0, swagger_1.ApiResponse)({ status: 201, description: 'Course created' }),
    (0, swagger_1.ApiResponse)({ status: 400, description: 'Validation error' }),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, course_dto_1.CreateCourseDto]),
    __metadata("design:returntype", void 0)
], CoursesController.prototype, "create", null);
__decorate([
    (0, common_1.Patch)(':id'),
    (0, swagger_1.ApiOperation)({ summary: 'Update a course' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Course updated' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'Course not found' }),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, course_dto_1.UpdateCourseDto]),
    __metadata("design:returntype", void 0)
], CoursesController.prototype, "update", null);
__decorate([
    (0, common_1.Delete)(':id'),
    (0, common_1.HttpCode)(common_1.HttpStatus.NO_CONTENT),
    (0, swagger_1.ApiOperation)({ summary: 'Delete a course' }),
    (0, swagger_1.ApiResponse)({ status: 204, description: 'Course deleted' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'Course not found' }),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], CoursesController.prototype, "remove", null);
__decorate([
    (0, common_1.Get)(':id/modules'),
    (0, swagger_1.ApiOperation)({ summary: 'List modules for a course' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'List of modules' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'Course not found' }),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], CoursesController.prototype, "listModules", null);
__decorate([
    (0, common_1.Post)(':id/modules'),
    (0, swagger_1.ApiOperation)({ summary: 'Add a module to a course' }),
    (0, swagger_1.ApiResponse)({ status: 201, description: 'Module created' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'Course not found' }),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, course_dto_1.CreateModuleDto]),
    __metadata("design:returntype", void 0)
], CoursesController.prototype, "addModule", null);
__decorate([
    (0, common_1.Patch)(':id/modules/:moduleId'),
    (0, swagger_1.ApiOperation)({ summary: 'Update a module' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Module updated' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'Module not found' }),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Param)('moduleId')),
    __param(3, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String, course_dto_1.UpdateModuleDto]),
    __metadata("design:returntype", void 0)
], CoursesController.prototype, "updateModule", null);
__decorate([
    (0, common_1.Delete)(':id/modules/:moduleId'),
    (0, common_1.HttpCode)(common_1.HttpStatus.NO_CONTENT),
    (0, swagger_1.ApiOperation)({ summary: 'Delete a module' }),
    (0, swagger_1.ApiResponse)({ status: 204, description: 'Module deleted' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'Module not found' }),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Param)('moduleId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", Promise)
], CoursesController.prototype, "removeModule", null);
__decorate([
    (0, common_1.Get)(':id/modules/:moduleId/lessons'),
    (0, swagger_1.ApiOperation)({ summary: 'List lessons for a module' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'List of lessons' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'Module not found' }),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)('moduleId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], CoursesController.prototype, "listLessons", null);
__decorate([
    (0, common_1.Post)(':id/modules/:moduleId/lessons'),
    (0, swagger_1.ApiOperation)({ summary: 'Add a lesson to a module' }),
    (0, swagger_1.ApiResponse)({ status: 201, description: 'Lesson created' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'Module not found' }),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)('moduleId')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, course_dto_1.CreateLessonDto]),
    __metadata("design:returntype", void 0)
], CoursesController.prototype, "addLesson", null);
__decorate([
    (0, common_1.Patch)(':id/modules/:moduleId/lessons/:lessonId'),
    (0, swagger_1.ApiOperation)({ summary: 'Update a lesson' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Lesson updated' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'Lesson not found' }),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)('moduleId')),
    __param(2, (0, common_1.Param)('lessonId')),
    __param(3, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String, course_dto_1.UpdateLessonDto]),
    __metadata("design:returntype", void 0)
], CoursesController.prototype, "updateLesson", null);
__decorate([
    (0, common_1.Delete)(':id/modules/:moduleId/lessons/:lessonId'),
    (0, common_1.HttpCode)(common_1.HttpStatus.NO_CONTENT),
    (0, swagger_1.ApiOperation)({ summary: 'Delete a lesson' }),
    (0, swagger_1.ApiResponse)({ status: 204, description: 'Lesson deleted' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'Lesson not found' }),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)('moduleId')),
    __param(2, (0, common_1.Param)('lessonId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", Promise)
], CoursesController.prototype, "removeLesson", null);
exports.CoursesController = CoursesController = __decorate([
    (0, swagger_1.ApiTags)('courses'),
    (0, swagger_1.ApiBearerAuth)(),
    (0, common_1.Controller)('courses'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __metadata("design:paramtypes", [courses_service_1.CoursesService])
], CoursesController);
let SubjectProgressController = class SubjectProgressController {
    courses;
    constructor(courses) {
        this.courses = courses;
    }
    progress(user, subjectId) {
        return this.courses.subjectProgress(user.id, subjectId);
    }
};
exports.SubjectProgressController = SubjectProgressController;
__decorate([
    (0, common_1.Get)(':id/progress'),
    (0, swagger_1.ApiOperation)({ summary: 'Get subject learning progress' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Progress summary' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'Subject not found' }),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], SubjectProgressController.prototype, "progress", null);
exports.SubjectProgressController = SubjectProgressController = __decorate([
    (0, swagger_1.ApiTags)('courses'),
    (0, swagger_1.ApiBearerAuth)(),
    (0, common_1.Controller)('subjects'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __metadata("design:paramtypes", [courses_service_1.CoursesService])
], SubjectProgressController);
//# sourceMappingURL=courses.controller.js.map