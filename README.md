# Focus OS

> A personal learning operating system for developers.
> **Plan → Focus → Track → Review → Improve.**

**V1 status:** Phase 0 complete — scaffolds only. Real features ship in Phases 1–6.
See [`docs/11-development-phases.md`](docs/11-development-phases.md).

---

## Repository layout

```
focus-os/
├── docs/         ← V1 planning blueprint (14 docs)
├── mobile/       ← Flutter app (Material 3 + Riverpod + Drift + GoRouter)
├── backend/      ← NestJS API (Prisma + PostgreSQL)
└── infra/        ← docker-compose for Postgres + pgAdmin
```

---

## Quick start

### 1. Start the database
```bash
cd infra
bash scripts/start-dev.sh
```
Postgres: `localhost:5434`  ·  pgAdmin: <http://localhost:5050> (admin@local.dev / admin)

### 2. Start the backend
```bash
cd backend
npm install
npx prisma migrate dev   # already applied; idempotent
npm run build
npm run start:dev
```
API: `http://localhost:3000/api/v1`  ·  Health: `GET /api/v1/health`

### 3. Run the mobile app
```bash
cd mobile
flutter pub get
dart run build_runner build       # codegen for Drift
flutter run
```

### 4. Run all tests
```bash
# Backend (after adding tests in Phase 1+)
cd backend && npm test

# Mobile
cd mobile && flutter test
```

---

## Tech stack

| Concern | Choice | Why |
|---|---|---|
| Mobile UI | Flutter 3.44 + Material 3 | One codebase, native feel |
| State | Riverpod 2.6 | Type-safe providers, easy testing |
| Local DB | Drift (SQLite) | Relational, joins, same SQL mindset as Postgres — see [docs/06-flutter-architecture.md](docs/06-flutter-architecture.md) |
| Networking | Dio | Interceptors, retries, easy mocking |
| Navigation | GoRouter | Declarative, deep-link friendly |
| Backend | NestJS | Native DI, module = domain |
| ORM | Prisma 6 | Type-safe, migrations, DX |
| DB | PostgreSQL 16 | Authoritative store, relational |

**No AI in V1/V2.** See [docs/13-future-ai-integration.md](docs/13-future-ai-integration.md).

---

## Why this is split this way

- **Mobile is offline-first.** All writes go to Drift first; an outbox queue syncs to the backend when online.
- **Sessions are timestamp-driven.** See [`mobile/lib/core/time/time_source.dart`](mobile/lib/core/time/time_source.dart) and `R-S2/R-S3/R-S16` in [docs/14-business-rules.md](docs/14-business-rules.md).
- **Backend is a thin CRUD + stats layer.** No business logic in controllers. See [docs/07-backend-architecture.md](docs/07-backend-architecture.md).
- **Stats are derived, not stored.** Daily totals and streaks are computed from `study_sessions` on demand (R-S8/R-S9).

---

## Current Phase 0 deliverables (✅ shipped)

- [x] Repo scaffold (`mobile/`, `backend/`, `infra/`, `docs/`)
- [x] Docker compose for Postgres 16 + pgAdmin on port **5434** (port 5432 was taken by another project on this host)
- [x] NestJS backend builds and runs, `GET /api/v1/health` returns 200
- [x] Prisma schema + initial migration applied — all 8 business tables exist
- [x] Flutter app boots; Material 3 theme, GoRouter, Drift empty database, Riverpod ProviderScope
- [x] `TimeSource` abstraction (R-S16) with `FakeClock` for tests
- [x] `flutter analyze` clean (1 info-level lint for generated file)
- [x] `flutter test` 6/6 green (TimeSource + dashboard smoke)
- [x] Build runner produces Drift generated file

---

## Next: Phase 1 (Auth + Areas + Subjects)

See [docs/11-development-phases.md](docs/11-development-phases.md) for the full plan.