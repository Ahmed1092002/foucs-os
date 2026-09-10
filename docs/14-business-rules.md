# 14 · Business Rules

> These are the **invariants** the app must always honor.
> Any PR that violates one is rejected.

## R-S1 · Planned vs Actual are separate numbers
- Every study session stores both `plannedDurationSeconds` and `actualDurationSeconds`.
- Stats always report them separately. Never summed into a single number.

## R-S2 · Actual duration is derived from timestamps
- `actual = endedAt − startedAt − pausedIntervals` (in seconds).
- We never persist a manually-typed duration except via this formula.
- Live display may use `now − startedAt − pausedIntervals` while running, but persisted `actualDurationSeconds` is only written on completion.

## R-S3 · Paused time is excluded from actual
- `pausedIntervalsSeconds` = sum of every pause interval.
- Pause intervals are `[pauseStart, resumeStart)` pairs; if the session ends while paused, the final open interval is closed at `endedAt`.

## R-S4 · A session belongs to exactly one subject — but history survives deletion
- `study_sessions.subject_id` is `NOT NULL` at write time, but the FK uses **`ON DELETE SET NULL`**.
- If a subject is deleted, its sessions stay and `subject_id` becomes `NULL`.
- UI shows these as *"Deleted subject"* (placeholder name + grey color) so totals and stats remain intact.
- We chose SET NULL over CASCADE deliberately to **preserve historical learning data** — a deleted subject must never erase the user's record of what they studied.

## R-S5 · A session may optionally belong to a lesson/topic
- `study_sessions.topic` is a free-text `text` in MVP.
- In V1, `study_sessions.lesson_id` FK nullable.
- Topic/lesson are **never required** — Quick Start must work with neither.

## R-S6 · Only completed sessions count toward stats/streaks
- `state = 'completed'` ⇒ counted.
- `state = 'cancelled'` ⇒ never counted.
- `state = 'running' | 'paused'` ⇒ excluded.

## R-S7 · Cancelled sessions are recorded but invisible
- We **do** persist cancelled sessions (with `state = 'cancelled'`, `endedAt`, no ratings).
- They appear in history (with a "Cancelled" badge) but contribute nothing to totals, streaks, or averages.

## R-S8 · Daily statistics are derived
- We never store "today's total" as a row.
- Dashboard / stats endpoints compute from `study_sessions` filtered by date range.
- This prevents drift between sessions and aggregates.

## R-S9 · Streak definition (MVP)
- A day counts if the user has **at least 1 completed session** that day (user's local timezone).
- `currentStreak` = number of consecutive counting-days ending today (or yesterday — see grace rule).
- `longestStreak` = max ever.
- **Grace rule (V2 candidate):** if today has no session yet but yesterday did, `currentStreak` still shows yesterday's count. Documented as a setting in V2.

## R-S10 · Planned vs actual roll-up
- For a date D:
  - `planned(D) = Σ durationSeconds` over `daily_plan_items` for D.
  - `actual(D) = Σ actualDurationSeconds` over `study_sessions` where `date(started_at) = D` and `state='completed'`.
- "Completion rate" = `actual / planned`, displayed as %, never as a pass/fail.

## R-S11 · Subject progress
- `completedHours(subject) = actualSeconds over its completed sessions / 3600`.
- `percentTime(subject) = clamp(completedHours / targetHours, 0, 1)`.
- `percentComplete(subject, MVP) = percentTime`.
- In V1, when lessons exist: `percentComplete = 0.5·percentTime + 0.5·percentLessons`. Documented in code.

## R-S12 · Goal completion rate (fixed formula)
- Per session: `goalResult ∈ {yes, partially, no, null}`.
- Aggregated per subject:

```
goalCompletionRate = (yesCount + 0.5 × partialCount) / totalAnswered
```

- `totalAnswered` = `yesCount + partialCount + noCount` (sessions with a non-null `goalResult`).
- Sessions with `goalResult = null` (user skipped) are **excluded** from both numerator and denominator — skipping is honest, never penalized.

## R-S13 · Sessions are immutable once completed
- After `state='completed'`, only `notes`, `focus_rating`, `energy_rating` may change.
- Any other field change attempts return `409 CONFLICT`.
- This protects historical stats.

## R-S14 · Soft delete is the norm
- Areas / subjects: soft delete (`archived_at` or `status='archived'`), never `DELETE FROM`.
- Hard delete only via account-deletion cascade.

## R-S15 · No guilt, no punishment
- No streak is decremented for low-output days; it simply ends.
- "Missed plan" messages are framed as suggestions, not failures.
- Copy is reviewed before merge.

## R-S16 · Time source is injectable
- All duration math depends on a `TimeSource` interface, not `DateTime.now()` directly.
- Production binds to `SystemClock`; tests bind to `FakeClock`.
- This is how we guarantee the timer math is correct.

## R-S17 · IDs are client-generated for offline writes
- All entities the user can create offline use UUID v4 generated on the device.
- The server trusts the ID (and returns 409 on collision, which is theoretically zero).

## R-S18 · Sync never loses a session
- Sessions are append-only in sync.
- If the server rejects a session (e.g. foreign-key issue), the client keeps it locally flagged as `syncStatus='conflict'` and surfaces it in Settings for the user to resolve. We never silently drop.