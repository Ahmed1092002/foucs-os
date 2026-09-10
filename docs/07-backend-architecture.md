# 07 · Backend Architecture (NestJS)

## Why NestJS
- Native DI + module boundaries match our domain split (auth, areas, subjects, sessions…).
- First-class TypeScript, decorators, validation pipes.
- Clean separation Controller → Service → Repository.
- Easy testing with `@nestjs/testing`.

## Module map
```
src/
├── main.ts
├── app.module.ts
├── common/
│   ├── filters/         # global HttpExceptionFilter
│   ├── interceptors/    # logging interceptor
│   ├── guards/          # JwtAuthGuard
│   ├── decorators/      # @CurrentUser
│   └── pipes/           # ZodValidationPipe
├── config/              # env validation (zod)
├── prisma/              # PrismaService
├── auth/
│   ├── auth.controller.ts
│   ├── auth.service.ts
│   ├── strategies/      # jwt.strategy.ts
│   └── dto/
├── users/
├── learning-areas/
├── subjects/
├── courses/             # V1
├── lessons/             # V1
├── study-sessions/
├── daily-plans/
├── daily-reviews/
├── statistics/          # read-only aggregations
├── notifications/       # V1
└── health/
```

## Each module — same shape
```
area/
├── area.module.ts
├── area.controller.ts        # thin: parse, delegate, respond
├── area.service.ts           # business rules
├── area.repository.ts        # Prisma queries
├── dto/
│   ├── create-area.dto.ts
│   └── update-area.dto.ts
└── entities/                 # response shape (optional, may use Prisma types)
```

**Rule:** controllers contain **no business logic**. They only:
1. Validate input (DTO + `ValidationPipe`).
2. Extract `userId` from JWT.
3. Call service.
4. Map exceptions to HTTP.

## Cross-cutting
| Concern | Implementation |
|---------|----------------|
| Auth | `@nestjs/passport` + passport-jwt, JwtAuthGuard global |
| Validation | `class-validator` + `ValidationPipe({whitelist:true, transform:true})` |
| Logging | `pino` via Nest logger, request id middleware |
| Errors | Custom `AppException` hierarchy → mapped by `HttpExceptionFilter` |
| Config | `zod`-validated env in `config/env.ts` |
| DB | `PrismaService` extends `PrismaClient`, global on `app.module` |
| CORS | Allow mobile origins only |

## API style
- REST under `/api/v1/...`.
- JSON only.
- Pagination: cursor-based on lists.
- Error envelope: `{ code, message, details? }`.

## Background jobs (V1)
- None required for MVP.
- `notifications` module may add a daily cron later (Nest `@Cron`).

## Testing
| Layer | Tool |
|-------|------|
| Unit | Jest |
| Service | Jest + mocked repository |
| API e2e | Jest + `supertest` + test Postgres |
| Fixtures | `prisma db seed` against test DB |

## Environment variables
```
NODE_ENV
PORT
DATABASE_URL
JWT_SECRET
JWT_ACCESS_TTL        # 15m
JWT_REFRESH_TTL       # 30d
LOG_LEVEL
CORS_ORIGINS          # csv
```