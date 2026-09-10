"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var HttpExceptionFilter_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.HttpExceptionFilter = void 0;
const common_1 = require("@nestjs/common");
let HttpExceptionFilter = HttpExceptionFilter_1 = class HttpExceptionFilter {
    logger = new common_1.Logger(HttpExceptionFilter_1.name);
    catch(exception, host) {
        const ctx = host.switchToHttp();
        const response = ctx.getResponse();
        const request = ctx.getRequest();
        let status = common_1.HttpStatus.INTERNAL_SERVER_ERROR;
        let envelope = {
            code: 'INTERNAL',
            message: 'Unexpected server error',
        };
        if (exception instanceof common_1.HttpException) {
            status = exception.getStatus();
            const body = exception.getResponse();
            envelope = this.fromHttpException(status, body);
        }
        else if (exception instanceof Error) {
            this.logger.error(`${request.method} ${request.url} → ${exception.message}`, exception.stack);
        }
        else {
            this.logger.error(`${request.method} ${request.url} → ${String(exception)}`);
        }
        response.status(status).json({
            ...envelope,
            path: request.url,
            method: request.method,
            timestamp: new Date().toISOString(),
        });
    }
    fromHttpException(status, body) {
        const code = this.codeForStatus(status);
        if (typeof body === 'string') {
            return { code, message: body };
        }
        if (typeof body === 'object' && body !== null) {
            const obj = body;
            return {
                code,
                message: typeof obj.message === 'string' ? obj.message : code,
                details: obj.message instanceof Array ? obj.message : obj.details,
            };
        }
        return { code, message: code };
    }
    codeForStatus(status) {
        switch (status) {
            case 400: return 'VALIDATION_ERROR';
            case 401: return 'UNAUTHENTICATED';
            case 403: return 'FORBIDDEN';
            case 404: return 'NOT_FOUND';
            case 409: return 'CONFLICT';
            case 429: return 'RATE_LIMITED';
            default: return status >= 500 ? 'INTERNAL' : 'ERROR';
        }
    }
};
exports.HttpExceptionFilter = HttpExceptionFilter;
exports.HttpExceptionFilter = HttpExceptionFilter = HttpExceptionFilter_1 = __decorate([
    (0, common_1.Catch)()
], HttpExceptionFilter);
//# sourceMappingURL=http-exception.filter.js.map