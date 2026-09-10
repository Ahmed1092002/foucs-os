"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
require("reflect-metadata");
const core_1 = require("@nestjs/core");
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const swagger_1 = require("@nestjs/swagger");
const app_module_1 = require("./app.module");
const http_exception_filter_1 = require("./common/filters/http-exception.filter");
async function bootstrap() {
    const app = await core_1.NestFactory.create(app_module_1.AppModule, { bufferLogs: true });
    const config = app.get(config_1.ConfigService);
    const swaggerConfig = new swagger_1.DocumentBuilder()
        .setTitle('Focus OS API')
        .setDescription('Personal learning operating system for developers')
        .setVersion('1.0')
        .addBearerAuth()
        .addTag('auth', 'Authentication')
        .addTag('areas', 'Learning areas')
        .addTag('subjects', 'Subjects / topics')
        .addTag('sessions', 'Study sessions')
        .addTag('plans', 'Daily plans')
        .addTag('reviews', 'Daily reviews')
        .addTag('courses', 'Courses & progress')
        .addTag('statistics', 'Statistics & analytics')
        .addTag('sync', 'Offline synchronization')
        .build();
    const document = swagger_1.SwaggerModule.createDocument(app, swaggerConfig);
    swagger_1.SwaggerModule.setup('api/docs', app, document, {
        swaggerOptions: { persistAuthorization: true },
    });
    app.setGlobalPrefix('api/v1');
    app.useGlobalPipes(new common_1.ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
        transformOptions: { enableImplicitConversion: true },
    }));
    app.useGlobalFilters(new http_exception_filter_1.HttpExceptionFilter());
    const origins = (config.get('CORS_ORIGINS') ?? '')
        .split(',')
        .map((s) => s.trim())
        .filter(Boolean);
    app.enableCors({ origin: origins.length ? origins : true, credentials: true });
    const port = config.get('PORT') ?? 3000;
    await app.listen(port);
    common_1.Logger.log(`Focus OS API listening on http://localhost:${port}/api/v1`, 'Bootstrap');
    common_1.Logger.log(`Swagger UI available at http://localhost:${port}/api/docs`, 'Bootstrap');
}
bootstrap();
//# sourceMappingURL=main.js.map