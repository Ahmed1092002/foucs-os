# 11 · Development Phases

> Each phase ends with a working, demoable slice.
> We never move on until that slice is green and reviewed.

---

## Phase 0 — Foundations (1 week)
- Repo scaffolding (`mobile/`, `backend/`, `infra/`, `docs/`).
- Docker compose: Postgres + pgAdmin.
- CI: lint + tests on PR.
- Theme, Material 3, GoRouter skeleton.
- Drift bootstrap (empty DB + migrations pipeline).
- NestJS bootstrap + Prisma + health route.

**Deliverable:** empty Flutter app launches; empty NestJS responds on `/health`; Postgres reachable.

---

## Phase 1 — Auth + Areas + Subjects (1 week)
- Backend: auth module (signup, login, refresh), areas, subjects (CRUD).
- Flutter: login/signup screens, areas list/create/edit, subjects list/create/edit.
- Local cache of areas/subjects.

**Deliverable:** user can sign up, create "Frontend" + "React" subject, restart app and still see them.

---

## Phase 2 — Study Session core (2 weeks)
- Backend: `study_sessions` CRUD + state transitions (`running`, `paused`, `completed`, `cancelled`).
- Flutter: `SessionTimer` (TimeSource-injected), TimerScreen, SummaryScreen, History tab.
- Drift table + DAO + outbox queue for sessions.
- Sync push (sessions only) + pull.

**Deliverable:** user can start, pause, complete, and see the session in History. Works offline.

---

## Phase 3 — Daily Planner + Dashboard (1 week)
- Backend: `daily_plans`, `/plans/:date`.
- Flutter: Planner screen, warning logic (>X hours/day).
- Dashboard: today's plan, totals, streak, completed-session count, active-session banner.

**Deliverable:** user plans tomorrow's study, opens the app, sees the plan, starts a session, dashboard reflects reality.

---

## Phase 4 — Statistics + Streaks + Sync hardening (1 week)
- Backend: `/stats/summary`, `/stats/by-subject`, `/stats/by-day`, `/stats/streak`.
- Flutter: Statistics screen (today + week), streak chip on Dashboard.
- Conflict resolution tests for sync.
- Retry + backoff for the outbox.

**Deliverable:** the app answers "how am I doing?" with real numbers.

---

## Phase 5 — MVP polish (1 week)
- Empty states, error states, loading skeletons.
- Daily review auto-summary.
- Form validation + UX flows.
- Test coverage on critical paths (timer math, streak math, sync).
- Release build.

**Deliverable:** MVP is shippable to TestFlight / internal track.

---

## Phase 6 — V1 features (3 weeks)
- Course → Module → Lesson tree + progress.
- Daily Review with ratings + free notes.
- All-time / monthly stats + charts.
- Local notifications (session reminders, goal nudges).
- Settings (timezone, daily limit, theme).
- Onboarding polish.

**Deliverable:** V1 in app stores.

---

## Phase 7 — V2 (NOT planned here)
- AI integration per [13 · Future AI Integration](./13-future-ai-integration.md).
- Multi-device real-time sync.
- Wear OS / watch companion.

---

## Critical-path checklist per phase
- [ ] Backend tests green
- [ ] Flutter unit + widget tests green
- [ ] Timer math tested with FakeClock
- [ ] Offline scenario manually verified
- [ ] DB migration applied + reversible
- [ ] Docs updated (this folder)