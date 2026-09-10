# 10 · Project Structure

```
focus-os/
├── docs/                      ← this folder (planning)
├── mobile/                    ← Flutter app
├── backend/                   ← NestJS API
├── infra/                     ← docker-compose, scripts, env templates
└── README.md                  ← entry point
```

---

## `mobile/` — Flutter

```
mobile/
├── pubspec.yaml
├── analysis_options.yaml
├── android/
├── ios/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── di/
│   │   ├── error/
│   │   ├── time/
│   │   ├── theme/
│   │   ├── router/
│   │   └── utils/
│   ├── features/
│   │   ├── auth/
│   │   ├── areas/
│   │   ├── subjects/
│   │   ├── sessions/
│   │   ├── planner/
│   │   ├── dashboard/
│   │   ├── history/
│   │   ├── statistics/
│   │   ├── streaks/
│   │   └── review/
│   ├── data/
│   │   ├── local/
│   │   │   ├── database.dart
│   │   │   ├── tables/
│   │   │   └── daos/
│   │   ├── remote/
│   │   │   ├── api_client.dart
│   │   │   └── dto/
│   │   └── sync/
│   │       ├── outbox.dart
│   │       └── sync_service.dart
│   └── shared/
│       ├── widgets/
│       └── extensions/
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
└── tool/
    └── build_runner.sh
```

Each feature follows:
```
features/<name>/
├── data/        # repositories implementing domain interfaces
├── domain/      # entities, value objects, use cases
└── presentation/# screens, widgets, providers
```

---

## `backend/` — NestJS

```
backend/
├── package.json
├── tsconfig.json
├── nest-cli.json
├── prisma/
│   ├── schema.prisma
│   ├── migrations/
│   └── seed.ts
├── src/
│   ├── main.ts
│   ├── app.module.ts
│   ├── common/
│   ├── config/
│   ├── prisma/
│   ├── auth/
│   ├── users/
│   ├── learning-areas/
│   ├── subjects/
│   ├── study-sessions/
│   ├── daily-plans/
│   ├── daily-reviews/
│   ├── statistics/
│   ├── notifications/
│   └── health/
└── test/
    ├── unit/
    └── e2e/
```

---

## `infra/`

```
infra/
├── docker-compose.yml         # postgres + pgadmin for local dev
├── docker-compose.test.yml
├── .env.example
└── scripts/
    ├── start-dev.sh
    ├── reset-db.sh
    └── seed.sh
```

---

## Naming conventions

| Item | Convention | Example |
|------|------------|---------|
| Dart files | `snake_case` | `study_session.dart` |
| Dart classes | `PascalCase` | `StudySession` |
| Provider names | `<feature><Type>` | `sessionsControllerProvider` |
| DB tables | `snake_case`, plural | `study_sessions` |
| API endpoints | `/api/v1/<plural>` | `/api/v1/sessions` |
| DTOs | `<Action><Entity>Dto` | `CreateSessionDto` |
| Migrations | `YYYYMMDDHHMMSS_name` | `20260903_create_study_sessions` |

---

## Branch strategy
- `main` — always shippable.
- `feat/*` — features.
- `fix/*` — bugfixes.
- `chore/*` — tooling.
- Conventional commits (`feat:`, `fix:`, `docs:`, `test:`, `refactor:`).