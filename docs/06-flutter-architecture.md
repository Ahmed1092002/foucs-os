# 06 · Flutter Architecture

## Layers (top → bottom)
```
Presentation  ──  widgets, screens, GoRouter
State         ──  Riverpod providers (AsyncNotifier, StreamProvider)
Domain        ──  pure Dart: entities, value objects, business rules
Data          ──  repositories → local (Drift) + remote (Dio)
Sync          ──  SyncService: queue + push + pull
Infra         ──  DI, logging, notifications, time source
```

## Why Drift over Isar
| Criterion | Drift (SQLite) | Isar (NoSQL) |
|-----------|----------------|--------------|
| Relational data (subject → course → lesson) | ✅ native joins | ⚠️ manual links |
| Complex queries (stats, streaks) | ✅ SQL | ⚠️ harder |
| Type-safe queries | ✅ code-gen | ✅ code-gen |
| Backend parity (Postgres is also SQL) | ✅ same mental model | ❌ different |
| Performance for this workload (few thousand rows) | ✅ more than enough | ✅ excellent |
| Offline sync of relational data | ✅ straightforward | ⚠️ denormalized |

**Decision: Drift.** Our domain is fundamentally relational (areas → subjects → sessions → reviews). Drift gives us joins, migrations, and a SQL mindset that mirrors the backend. Isar is faster at scale but our scale is tiny and the modeling friction is real.

## State management — Riverpod 2
- `@riverpod` codegen for typed providers.
- Three patterns:
  - `AsyncNotifierProvider` for CRUD lists (areas, subjects, sessions).
  - `StreamProvider` for live timer ticking.
  - `Provider` for repositories / services injected via DI.

## Project structure
```
mobile/
├── lib/
│   ├── main.dart
│   ├── app.dart                    # MaterialApp + theme + router
│   ├── core/
│   │   ├── di/                     # provider overrides
│   │   ├── error/                  # Failure, Exception types
│   │   ├── time/                   # TimeSource (clock injection for tests)
│   │   ├── theme/                  # Material 3 theme
│   │   └── router/                 # GoRouter config
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── areas/
│   │   ├── subjects/
│   │   ├── sessions/
│   │   │   ├── data/
│   │   │   ├── domain/             # SessionTimer, PlannedVsActual
│   │   │   ├── application/        # StartSession, PauseSession, ...
│   │   │   └── presentation/       # TimerScreen, SummaryScreen
│   │   ├── planner/
│   │   ├── dashboard/
│   │   ├── history/
│   │   ├── statistics/
│   │   ├── streaks/
│   │   └── review/
│   ├── data/
│   │   ├── local/                  # Drift database, tables, DAOs
│   │   ├── remote/                 # Dio client, DTOs, mappers
│   │   └── sync/                   # SyncService, OutboxQueue
│   └── shared/
│       ├── widgets/
│       └── extensions/
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
└── pubspec.yaml
```

## Timer design — the heart of the app
```
SessionTimer
   ├── state:    idle | running | paused | completed
   ├── inputs:   start(), pause(), resume(), stop(), complete()
   ├── source:   TimeSource (real Clock in prod, FakeClock in tests)
   ├── math:     actualSeconds = (now − startedAt) − Σ pausedIntervals
   └── emits:    SessionTimerState via StreamProvider
```

**Key rules**
- The UI **never** owns duration. It only displays `(now − startedAt − paused)`.
- `pausedAt` is recorded on pause; on resume, `pausedIntervals += now − pausedAt`.
- This makes the timer **drift-proof** across lock, background, and kill.

## Offline-first storage
- Every write goes to Drift first.
- Each row has `id`, `updatedAt`, `syncStatus` (`synced | dirty | conflict`).
- `OutboxQueue` stores pending mutations (`CREATE / UPDATE / DELETE` envelopes).
- `SyncService` runs:
  1. Drain outbox → push to backend.
  2. Pull changes since `lastPulledAt` (per collection).
  3. Apply **last-writer-wins** on scalars, **append-only** on sessions/reviews (never lose a logged event).

## Navigation (GoRouter)
```
/                          → redirect to /dashboard or /login
/login
/signup
/dashboard                  # home
/areas
/areas/:areaId
/subjects/:subjectId
/courses/:courseId          # V1
/planner
/quick-start
/session/active             # full-screen timer
/session/:sessionId/summary
/history
/history/:sessionId
/statistics
/review                     # daily review entry
/settings
```

## Theming
- Material 3, dynamic color (Android 12+) with manual seed fallback.
- One neutral palette + per-area accent color chosen at creation.
- Typography: Inter or system default.
- No animation unless it conveys state (timer pulse, session complete).