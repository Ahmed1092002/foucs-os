# 02 · Feature Map

Legend: ✅ MVP (must ship) · 🟡 V1 (ship in V1) · ⚪ Future · 🚫 V1 anti-feature

## A. Dashboard ✅
- Today's total planned study time
- Today's actual study time
- Remaining planned time
- Completed session count
- Current streak
- Today's plan list (with status icons)
- Active session banner (if any)
- Progress bar toward today's goal

## B. Learning Areas ✅
- CRUD areas (Frontend, Backend, DevOps…)
- Color + icon per area
- List view with aggregated stats
- Soft delete (no hard delete in MVP)

## C. Subjects ✅
- CRUD subjects inside an area
- Fields: name, description, color, icon, **target hours**, status, priority, createdAt, optional deadline
- Subject detail: target vs completed, progress %, session count

## D. Courses / Modules / Lessons 🟡
- **MVP:** lessons can be attached to a session by free-text topic.
- **V1:** formal Course → Module → Lesson tree with status (Not started / In progress / Done).
- Progress is tracked per-lesson and rolls up to subject.

> **Why split:** Many learners study without a structured course. Forcing the Course tree in MVP would over-fit. We add the tree in V1 when the data model is already in place.

## E. Study Session ✅
- Quick Start: subject → duration → optional topic → start
- Start / Pause / Resume / Stop / Complete
- Timestamps drive actual duration (not increment counter)
- Survives background, screen lock, app kill
- Session summary screen with goal result + energy/focus 1–5
- Optional notes

## F. Daily Planner ✅
- Add plan items: subject, start time, duration
- Validation: warn if total planned > X hours (deterministic, configurable)
- Today's plan visible on Dashboard
- Tomorrow planning accessible

## G. Daily Review 🟡
- **MVP:** auto-summary of today's planned vs actual.
- **V1:** productivity / energy / focus 1–5 ratings + "what went well / what blocked you" notes.

## H. Statistics 🟡
- **MVP:** today + this-week totals, per-subject breakdown, planned vs actual.
- **V1:** month + all-time, completion rate, most/least studied, streak history.

## I. Progress Tracking ✅
- Time progress: completedHours / targetHours
- Goal completion: aggregate of session goal results
- Course/lesson progress: 🟡 (V1)
- Overall progress algorithm → see [14 · Business Rules](./14-business-rules.md)

## J. Streaks ✅
- Current streak
- Longest streak
- **Definition (MVP):** a day counts if ≥ 1 completed session exists for that day.
- Configurable threshold deferred to post-V1.

## K. Session History ✅
- List all sessions
- Filter by date range / subject / area
- Detail screen

## L. Notifications 🟡
- **MVP:** none.
- **V1:** local notifications — "session starts in 10 min", "you haven't completed today's goal".

## M. Authentication ✅
- Email + password (JWT)
- Local user profile cached for offline

## N. Sync ✅
- Push pending mutations when online
- Pull latest state on app start
- Conflict policy: **last-writer-wins** for fields, **additive** for sessions/reviews (never lose a logged session).

## O. Future AI (NOT in V1) ⚪
- See [13 · Future AI Integration](./13-future-ai-integration.md)

## P. Anti-features (explicitly OUT of V1) 🚫
- Chatbot / LLM
- AI planner
- AI recommendations
- AI-generated summaries
- Social / sharing
- Cloud sync of media
- Multi-device real-time sync

> **V1 guardrail:** `backend/src/ai/`, `pubspec.yaml`, and `package.json` MUST NOT contain any AI SDK, LLM client, or `openai`/`anthropic`/`gemini` dependency. Pull requests that introduce AI code are rejected. The `13 · Future AI Integration` doc is the only place AI appears in source-controlled planning.