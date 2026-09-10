# 09 · API Design (REST · `/api/v1`)

> Conventions
> - All endpoints require `Authorization: Bearer <jwt>` except `/auth/*`.
> - Request/response bodies are JSON.
> - All timestamps are **ISO 8601 UTC** unless suffixed `Z`.
> - Durations are **integer seconds** (`plannedDurationSeconds`, etc.).
> - IDs are **UUID v4** generated **client-side** for offline writes.

---

## Auth
| Method | Path | Body | Response |
|--------|------|------|----------|
| POST | `/auth/signup` | `{email, password, timezone}` | `{accessToken, refreshToken, user}` |
| POST | `/auth/login` | `{email, password}` | `{accessToken, refreshToken, user}` |
| POST | `/auth/refresh` | `{refreshToken}` | `{accessToken, refreshToken}` |
| POST | `/auth/logout` | — | `204` |

`POST /auth/signup` also creates a default area "General" server-side.

---

## Learning Areas
| Method | Path | Body | Response |
|--------|------|------|----------|
| GET | `/areas?includeArchived=false` | — | `Area[]` |
| POST | `/areas` | `{id, name, color, icon?}` | `Area` |
| PATCH | `/areas/:id` | `{name?, color?, icon?, archived?}` | `Area` |
| DELETE | `/areas/:id` | — | `204` (soft delete via `archived=true`) |

```json
Area {
  "id": "uuid",
  "name": "Frontend",
  "color": "#5B8DEF",
  "icon": "code",
  "archivedAt": null,
  "createdAt": "...",
  "updatedAt": "..."
}
```

---

## Subjects
| Method | Path | Body | Response |
|--------|------|------|----------|
| GET | `/subjects?areaId=&status=` | — | `Subject[]` |
| GET | `/subjects/:id` | — | `SubjectDetail` |
| POST | `/subjects` | `{id, areaId, name, description?, color?, targetHours, priority?, deadline?}` | `Subject` |
| PATCH | `/subjects/:id` | partial | `Subject` |
| DELETE | `/subjects/:id` | — | `204` |

`SubjectDetail` includes `completedHours`, `percentComplete`, `sessionsCount`.

---

## Study Sessions
| Method | Path | Body | Response |
|--------|------|------|----------|
| GET | `/sessions?from=&to=&subjectId=&areaId=&limit=&cursor=` | — | `SessionPage` |
| GET | `/sessions/active` | — | `Session?` |
| GET | `/sessions/:id` | — | `Session` |
| POST | `/sessions` | `Session` (client-issued `id`, `startedAt`) | `Session` |
| PATCH | `/sessions/:id` | partial | `Session` |
| POST | `/sessions/:id/complete` | `{actualDurationSeconds, pausedIntervalsSeconds, goalResult, focusRating, energyRating, notes?}` | `Session` |
| POST | `/sessions/:id/cancel` | — | `Session` |

```json
Session {
  "id": "uuid",
  "subjectId": "uuid",
  "topic": "useEffect",
  "plannedDurationSeconds": 3600,
  "startedAt": "2026-09-03T09:00:00Z",
  "endedAt": null,
  "actualDurationSeconds": null,
  "pausedIntervalsSeconds": 0,
  "state": "running",        // running | paused | completed | cancelled
  "goalText": "Understand when useEffect should/shouldn't be used",
  "goalResult": null,        // yes | partially | no
  "focusRating": null,
  "energyRating": null,
  "notes": null,
  "createdAt": "...",
  "updatedAt": "..."
}
```

---

## Daily Planner
| Method | Path | Body | Response |
|--------|------|------|----------|
| GET | `/plans?from=&to=` | — | `DailyPlan[]` (with items) |
| GET | `/plans/:date` | — | `DailyPlan` |
| PUT | `/plans/:date` | `{items: [{subjectId, startTime, durationSeconds, orderIndex?}]}` | `DailyPlan` |
| DELETE | `/plans/:date` | — | `204` |

---

## Daily Review (V1)
| Method | Path | Body | Response |
|--------|------|------|----------|
| GET | `/reviews?from=&to=` | — | `DailyReview[]` |
| GET | `/reviews/:date` | — | `DailyReview` |
| PUT | `/reviews/:date` | `{productivityRating, energyRating, focusRating, wentWell?, blockedBy?}` | `DailyReview` |

---

## Statistics
| Method | Path | Description |
|--------|------|-------------|
| GET | `/stats/summary?range=today\|week\|month\|all` | `{totalPlanned, totalActual, sessionsCompleted, completionRate}` |
| GET | `/stats/by-subject?range=week` | `[{subjectId, name, color, actualSeconds, sessionsCount}]` |
| GET | `/stats/by-day?from=&to=` | `[{date, planned, actual, sessionsCompleted}]` |
| GET | `/stats/streak` | `{current, longest, lastStudyDate}` |

---

## Sync helpers
| Method | Path | Body | Response |
|--------|------|------|----------|
| POST | `/sync/push` | `{mutations: [{op, entity, payload, clientUpdatedAt}]}` | `{results: [{id, status, serverUpdatedAt?}]}` |
| GET | `/sync/pull?since=ISO&entities=area,subject,session,...` | — | `{changes: [...], serverTime}` |

---

## Error envelope
```json
{
  "code": "VALIDATION_ERROR",
  "message": "plannedDurationSeconds must be > 0",
  "details": { "field": "plannedDurationSeconds" }
}
```

Standard codes: `UNAUTHENTICATED`, `FORBIDDEN`, `NOT_FOUND`, `VALIDATION_ERROR`, `CONFLICT`, `RATE_LIMITED`, `INTERNAL`.