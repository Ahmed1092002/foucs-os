# Focus OS

> A personal learning operating system for developers.
> **Plan → Focus → Track → Review → Improve.**

**V1 status:** ✅ **Feature-complete** (Phases 0–7 done). Ready for deployment.
See [`docs/11-development-phases.md`](docs/11-development-phases.md).

---

## Repository layout

```
focus-os/
├── docs/              ← V1 planning blueprint (14 docs)
├── mobile/            ← Flutter app (Material 3 + Riverpod + Drift + GoRouter)
├── backend/           ← NestJS API (Prisma + PostgreSQL)
├── infra/             ← docker-compose for Postgres + pgAdmin + Backend
├── .github/workflows/ ← CI/CD: test, build, deploy
├── render.yaml        ← Render IaC (Backend + Managed Postgres)
└── .env.example       ← Environment variables template
```

---

## Quick Start (Local)

### 1. Start everything with Docker Compose
```bash
cd infra
docker compose up -d
```
- Postgres: `localhost:5434`
- pgAdmin: <http://localhost:5050> (admin@local.dev / admin)
- Backend API: `http://localhost:3000/api/v1` (Swagger: `/api/docs`)

### 2. Or run manually

**Backend:**
```bash
cd backend
cp ../.env.example .env   # edit values
npm install
npx prisma migrate dev
npm run build
npm run start:dev
```

**Mobile:**
```bash
cd mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### 3. Run tests
```bash
# Backend
cd backend && npm test

# Mobile (72 tests)
cd mobile && flutter test
```

---

## Deploy to Production (Render + Vercel)

### Prerequisites
- GitHub repo connected to Render & Vercel
- Secrets configured in GitHub Actions (see below)

### 1. Render (Backend + Postgres)
```bash
# Option A: IaC (recommended)
render deploy --confirm   # uses render.yaml

# Option B: Manual
# - Create Managed Postgres on Render
# - Create Web Service: build= "npm ci && npx prisma migrate deploy && npx nest build"
# - Start: "node dist/main.js"
# - Add env vars from .env.example
```

### 2. Vercel (Flutter Web)
```bash
# Connect repo to Vercel
# Framework: Other
# Build: flutter build web --release --dart-define=API_BASE_URL=https://your-api.onrender.com/api/v1
# Output: build/web
```

### 3. GitHub Actions Secrets
| Secret | Description |
|--------|-------------|
| `VERCEL_TOKEN` | From Vercel account settings |
| `VERCEL_ORG_ID` | `vercel inspect` output |
| `VERCEL_PROJECT_ID` | `vercel inspect` output |
| `RENDER_API_KEY` | Render account → API Keys |
| `RENDER_SERVICE_ID` | From Render service URL |

### 4. Push to main → auto-deploys
```bash
git push origin main
# → Runs CI (lint, test, build)
# → Deploys Flutter Web to Vercel
# → Triggers Render deploy for API
# → Mobile APK/AAB artifacts uploaded (30-day retention)
```

---

## Mobile Release Builds (APK/AAB)

**Windows has a Kotlin incremental compilation bug** with `shared_preferences_android` (AGP 9.x).
→ **Release builds MUST run on Linux (CI).**

```bash
# Local debug (works)
flutter run

# Release APK/AAB → use GitHub Actions or Codemagic
# Artifacts: build/app/outputs/flutter-apk/app-release.apk
#            build/app/outputs/bundle/release/app-release.aab
```

See `mobile/BUILD_WORKAROUND.md` for details.

---

## Tech Stack

| Concern | Choice | Why |
|---|---|---|
| Mobile UI | Flutter 3.44 + Material 3 | One codebase, native feel |
| State | Riverpod 2.6 | Type-safe providers, easy testing |
| Local DB | Drift (SQLite) | Relational, joins, same SQL mindset as Postgres |
| Networking | Dio | Interceptors, retries, easy mocking |
| Navigation | GoRouter | Declarative, deep-link friendly |
| Backend | NestJS | Native DI, module = domain |
| ORM | Prisma 6 | Type-safe, migrations, DX |
| DB | PostgreSQL 16 | Authoritative store, relational |
| API Docs | Swagger/OpenAPI | `/api/docs` with Bearer auth |

**No AI in V1.** See [`docs/13-future-ai-integration.md`](docs/13-future-ai-integration.md).

---

## Key Architecture Decisions

- **Offline-first mobile** — All writes → Drift → outbox queue → sync when online
- **Timestamp-driven sessions** — `TimeSource` abstraction, `actual = endedAt - startedAt - paused`
- **Backend = thin CRUD + stats** — No business logic in controllers
- **Stats derived on demand** — From `study_sessions`, not stored
- **Planned vs Actual always separate** — Core product principle

---

## Current Features (V1 Complete)

| Feature | Status |
|---|---|
| Auth (JWT + refresh) | ✅ |
| Learning Areas + Subjects | ✅ |
| Courses / Modules / Lessons | ✅ |
| Study Timer (pause/resume/background) | ✅ |
| Quick Start | ✅ |
| Daily Planner | ✅ |
| Daily Review (end-of-day) | ✅ |
| Statistics (week/month/all, streaks) | ✅ |
| Progress Tracking (time + lessons) | ✅ |
| Session History (filterable) | ✅ |
| Local Notifications (session reminders, daily nudge) | ✅ |
| Settings (theme, timezone, threshold, notifications) | ✅ |
| Offline Sync (push outbox + pull server changes) | ✅ |
| Swagger API Docs (`/api/docs`) | ✅ |
| CI/CD (GitHub Actions → Render + Vercel) | ✅ |

---

## Documentation

| File | Purpose |
|---|---|
| `docs/01-product-overview.md` | Product vision |
| `docs/02-feature-map.md` | All features mapped |
| `docs/03-user-flows.md` | Key user journeys |
| `docs/04-mvp-definition.md` | MVP scope |
| `docs/05-system-architecture.md` | System diagram |
| `docs/06-flutter-architecture.md` | Mobile architecture |
| `docs/07-backend-architecture.md` | Backend architecture |
| `docs/08-database-schema.md` | ERD + tables |
| `docs/09-api-design.md` | REST endpoints |
| `docs/10-project-structure.md` | Folder conventions |
| `docs/11-development-phases.md` | 7-phase build log |
| `docs/12-risks-edge-cases.md` | Known risks |
| `docs/13-future-ai-integration.md` | AI-ready hooks |
| `docs/14-business-rules.md` | Formal rules (R-S1...) |

---

## License
MIT — build your own learning OS.