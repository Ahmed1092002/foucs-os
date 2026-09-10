# 08 · Database Schema (PostgreSQL)

## ERD overview
```
User 1──┬──* LearningArea 1──* Subject 1──* StudySession
        │                          │
        │                          └──* (optional) Course 1──* Module 1──* Lesson
        │                                                            ▲
        │                                                            │
        └──────────────* DailyPlan 1──* DailyPlanItem ───────────────┘
        └──────────────* DailyReview (1 per user per date)
        └──────────────* Notification (V1)
```

## Tables (MVP)

### `users`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | default `gen_random_uuid()` |
| email | citext UNIQUE NOT NULL | |
| password_hash | text NOT NULL | bcrypt |
| timezone | text NOT NULL DEFAULT 'UTC' | IANA |
| created_at | timestamptz NOT NULL DEFAULT now() |
| updated_at | timestamptz NOT NULL DEFAULT now() |

### `learning_areas`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| user_id | uuid FK → users(id) ON DELETE CASCADE | |
| name | text NOT NULL | |
| color | text NOT NULL | hex |
| icon | text | icon name |
| archived_at | timestamptz NULL | soft delete |
| created_at | timestamptz NOT NULL DEFAULT now() |
| updated_at | timestamptz NOT NULL DEFAULT now() |

Indexes: `(user_id)`, `(user_id, archived_at)`.

### `subjects`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| user_id | uuid FK → users(id) ON DELETE CASCADE | |
| area_id | uuid FK → learning_areas(id) ON DELETE CASCADE | |
| name | text NOT NULL | |
| description | text NULL | |
| color | text NULL | inherits from area if null |
| target_hours | numeric(6,2) NOT NULL DEFAULT 0 | |
| status | text NOT NULL DEFAULT 'active' | active/paused/done |
| priority | smallint NOT NULL DEFAULT 0 | 0–3 |
| deadline | date NULL | |
| created_at | timestamptz NOT NULL DEFAULT now() |
| updated_at | timestamptz NOT NULL DEFAULT now() |

Indexes: `(user_id)`, `(area_id)`, `(user_id, status)`.

### `study_sessions`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| user_id | uuid FK → users(id) ON DELETE CASCADE | |
| subject_id | uuid FK → subjects(id) **ON DELETE SET NULL** | preserve history (see R-S4) |
| topic | text NULL | free text in MVP |
| planned_duration_seconds | integer NOT NULL | |
| started_at | timestamptz NOT NULL | |
| ended_at | timestamptz NULL | set on stop/complete |
| actual_duration_seconds | integer NULL | computed on complete |
| paused_intervals_seconds | integer NOT NULL DEFAULT 0 | sum of pauses |
| state | text NOT NULL | running/paused/completed/cancelled |
| goal_text | text NULL | |
| goal_result | text NULL | yes/partially/no (set on complete) |
| focus_rating | smallint NULL | 1–5 |
| energy_rating | smallint NULL | 1–5 |
| notes | text NULL | |
| created_at | timestamptz NOT NULL DEFAULT now() |
| updated_at | timestamptz NOT NULL DEFAULT now() |

Indexes:
- `(user_id, started_at DESC)` — history + stats
- `(user_id, state)` — active session lookup
- `(subject_id, started_at DESC)` — per-subject stats
- Partial: `(user_id) WHERE state = 'completed'` — streak / totals

### `daily_plans`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| user_id | uuid FK | |
| plan_date | date NOT NULL | |
| created_at | timestamptz NOT NULL DEFAULT now() |

Unique: `(user_id, plan_date)`.

### `daily_plan_items`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| daily_plan_id | uuid FK → daily_plans(id) ON DELETE CASCADE | |
| subject_id | uuid FK → subjects(id) ON DELETE CASCADE | |
| start_time | time NOT NULL | |
| duration_seconds | integer NOT NULL | |
| order_index | smallint NOT NULL DEFAULT 0 | |

Indexes: `(daily_plan_id, order_index)`.

### `daily_reviews`  *(V1 — create table in MVP to avoid migration churn)*
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| user_id | uuid FK | |
| review_date | date NOT NULL | |
| productivity_rating | smallint NULL | 1–5 |
| energy_rating | smallint NULL | 1–5 |
| focus_rating | smallint NULL | 1–5 |
| went_well | text NULL | |
| blocked_by | text NULL | |
| created_at | timestamptz NOT NULL DEFAULT now() |

Unique: `(user_id, review_date)`.

### `notifications`  *(V1)*
| id | uuid PK |
| user_id | uuid FK |
| type | text |
| payload | jsonb |
| scheduled_for | timestamptz |
| delivered_at | timestamptz NULL |
| created_at | timestamptz |

## Course tree *(V1 only)*
`courses` (subject_id FK), `modules` (course_id FK), `lessons` (module_id FK, status text).

## Client-issued IDs
- `study_sessions.id` is **client-generated UUID** so offline-created sessions don't need a round-trip to get an ID.
- Same for `subjects`, `areas`, `plans`, `reviews` once V1 allows multiple devices.

## Constraints & invariants (enforced in DB where possible)
- `study_sessions.ended_at >= started_at` (CHECK).
- `study_sessions.actual_duration_seconds <= ended_at − started_at` (CHECK).
- `daily_plan_items.duration_seconds > 0` (CHECK).
- All FKs `ON DELETE CASCADE` from user → child rows (account deletion wipes everything).

## Migrations
- Single source of truth: `backend/prisma/migrations/`.
- `prisma migrate dev` for local.
- `prisma migrate deploy` for CI/CD.