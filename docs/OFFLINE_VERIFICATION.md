# Offline-First Verification Checklist

This document verifies that Focus OS works correctly in offline scenarios and synchronizes properly when connectivity is restored.

## Architecture Summary

- **Local DB**: Drift (SQLite) — source of truth for all reads
- **Outbox**: `outbox_entries` table — mutations queued for server sync
- **SyncService**: `drainOutbox()` pushes local changes; `pull(since)` fetches server changes
- **Conflict Resolution**: Last-writer-wins by `updatedAt` timestamp

---

## Test Scenarios

### 1. Start session offline ✅
- [ ] Turn off network (airplane mode)
- [ ] Open app → Dashboard
- [ ] Tap "Quick Start" → pick subject + duration → Start
- [ ] Timer runs, shows elapsed time
- [ ] Pause / Resume works
- [ ] Complete session → Summary screen appears
- [ ] Session saved locally (check `studySessions` table)

### 2. View existing data offline ✅
- [ ] With network off, navigate to:
  - [ ] Dashboard (shows cached stats)
  - [ ] Areas list
  - [ ] Subject detail (course tree)
  - [ ] History (session list)
  - [ ] Statistics
  - [ ] Planner
  - [ ] Settings

### 3. Create data offline ✅
- [ ] Create new Area
- [ ] Create new Subject inside area
- [ ] Add Course / Module / Lesson
- [ ] Create Daily Plan for today
- [ ] Submit Daily Review
- [ ] All operations show no network errors
- [ ] Data visible immediately in UI

### 4. Outbox queue populated ✅
- [ ] Check `outbox_entries` table has rows for each mutation
- [ ] `syncStatus` = `dirty` for new/updated entities
- [ ] `attempts` = 0 initially

### 5. Reconnect → auto-sync on app start ✅
- [ ] Turn network back on
- [ ] Kill app (swipe away) and relaunch
- [ ] Observe: outbox drains (pushed to server)
- [ ] Observe: pull fetches any server changes
- [ ] Check `lastPulledAt` updated in settings

### 6. Manual "Sync now" in Settings ✅
- [ ] Open Settings → tap "Sync now"
- [ ] Loading spinner shows
- [ ] Result message: "Pushed X change(s). Pulled from server."
- [ ] No errors

### 7. Conflict resolution ✅
- [ ] On Device A (online): update a Subject's name
- [ ] On Device B (offline): update same Subject's name differently
- [ ] Device B comes online → sync
- [ ] Last-writer-wins: server's `updatedAt` determines winner
- [ ] Both devices eventually consistent

### 8. Large dataset sync ✅
- [ ] 50+ areas, 200+ subjects, 500+ sessions
- [ ] Pull completes without timeout
- [ ] UI remains responsive during sync (background isolate)

### 9. Partial sync failure handling ✅
- [ ] Simulate server 500 on one entity type
- [ ] Other entities still sync
- [ ] Failed rows remain in outbox with `attempts` incremented
- [ ] Retry on next sync attempt

### 10. Auth token expiry during sync ✅
- [ ] Expire access token (or wait for expiry)
- [ ] Trigger sync
- [ ] Auto-refresh kicks in
- [ ] Sync completes with new token

---

## Database Schema Checks

### Local Tables (Drift)
- [ ] `areas` — has `syncStatus` column (synced/dirty/conflict)
- [ ] `subjects` — has `syncStatus` column
- [ ] `studySessions` — has `syncStatus` column
- [ ] `courses`, `modules`, `lessons` — have `syncStatus` columns
- [ ] `dailyPlans`, `dailyPlanItems` — have `syncStatus`
- [ ] `dailyReviews` — have `syncStatus`
- [ ] `outboxEntries` — `entity`, `op`, `entityId`, `payload`, `attempts`, `createdAt`
- [ ] All tables have `updatedAt` for conflict resolution

### Server Tables (Prisma)
- [ ] All entities have `updatedAt @updatedAt`
- [ ] `User` has `timezone`
- [ ] Proper indexes on `userId`, `updatedAt`

---

## Sync Endpoint Contract

### `GET /api/v1/sync/pull?since=ISO8601`
Returns:
```json
{
  "serverTime": "2026-09-07T12:00:00.000Z",
  "since": "2026-09-07T10:00:00.000Z",
  "areas": [...],
  "subjects": [...],
  "sessions": [...],
  "dailyPlans": [...],
  "dailyReviews": [...],
  "courses": [...],
  "modules": [...],
  "lessons": [...]
}
```

### Push (via existing REST endpoints)
- `POST /areas`, `PATCH /areas/:id`
- `POST /subjects`, `PATCH /subjects/:id`
- `POST /sessions`, `PATCH /sessions/:id`, `POST /sessions/:id/complete`, `POST /sessions/:id/cancel`
- `POST /plans/:date`, `PUT /plans/:date`
- `PUT /reviews/:date`
- `POST /courses`, `PATCH /courses/:id`
- `POST /courses/:id/modules`, `PATCH /courses/:id/modules/:moduleId`
- `POST /courses/:id/modules/:moduleId/lessons`, `PATCH /courses/:id/modules/:moduleId/lessons/:lessonId`

---

## Known Limitations (V1)

1. **Single `lastPulledAt`** — coarse cursor; per-entity cursors planned for V2
2. **No background sync** — only on app start + manual; WorkManager/Firebase planned for V2
3. **No conflict UI** — conflicts auto-resolved by timestamp; user-facing resolver in V2
4. **No delta compression** — full entity pulled; acceptable for V1 dataset sizes
5. **No server-side soft-delete sync** — `archivedAt` on areas works but not fully synced

---

## Verification Status

| Scenario | Status | Notes |
|----------|--------|-------|
| Start session offline | ✅ Implemented | Timer uses `TimeSource` (wall-clock) |
| View data offline | ✅ Implemented | All reads from Drift |
| Create data offline | ✅ Implemented | Mutations write to Drift + outbox |
| Outbox queue | ✅ Implemented | `SyncService.drainOutbox()` |
| Auto-sync on start | ✅ Implemented | `AuthController._pushAndPull()` |
| Manual sync | ✅ Implemented | Settings screen "Sync now" |
| Conflict resolution | ✅ Implemented | LWW by `updatedAt` in `SyncService._applyPull()` |
| Large dataset | ⏳ Untested | Needs load testing |
| Partial failure | ✅ Implemented | Per-row try/catch, attempts++ |
| Token expiry | ✅ Implemented | `ApiClient` auto-refresh interceptor |

---

## To Run Verification

```bash
# 1. Start backend + DB
cd backend && npm run start:dev &

# 2. Run Flutter app on device/emulator
cd mobile && flutter run

# 3. Follow test scenarios above
```

---

## Sign-off

- [ ] All ✅ scenarios verified on physical device (Android)
- [ ] All ✅ scenarios verified on emulator (iOS if available)
- [ ] No data loss observed during offline→online transitions
- [ ] Sync completes within 10s for typical dataset (< 1000 rows)
- [ ] CI pipeline builds + tests pass

**Date**: ___________  
**Verified by**: ___________