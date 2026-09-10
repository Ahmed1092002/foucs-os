# 04 · MVP Definition

> MVP = the smallest build that solves the **core problem** and feels like a real product.

## What's in the MVP
| # | Feature | Why it's MVP-essential |
|---|---------|------------------------|
| 1 | **Authentication** | Multi-user data must be private. |
| 2 | **Learning Areas (CRUD)** | Top-level grouping for subjects. |
| 3 | **Subjects (CRUD)** | Cannot study without a subject. |
| 4 | **Quick Start session** | Fastest path from intent → focus. |
| 5 | **Focused Timer** | The "OS" promise is centered here. |
| 6 | **Pause / Resume** | Real life interrupts. |
| 7 | **Session Summary** | Planned vs actual must be visible. |
| 8 | **Session History** | Users need to see what they did. |
| 9 | **Daily Planner** | Without planning, "today's plan" on dashboard is empty. |
| 10 | **Dashboard** | The home screen. |
| 11 | **Basic Statistics** (today, week, per-subject, planned vs actual) | Closes the loop. |
| 12 | **Progress tracking** (time + goal result) | Validates the "OS" framing. |
| 13 | **Streaks** | Lightweight motivation layer. |
| 14 | **Local persistence** | Offline-first non-negotiable. |
| 15 | **Backend sync** | Data must survive device loss. |

## What's deliberately NOT in MVP
- Course → Module → Lesson tree (V1)
- Daily Review ratings (V1) — only auto-summary in MVP
- Notifications (V1)
- All-time / monthly stats (V1)
- Charts library polish (V1)
- Settings screen polish (V1)
- Theming / dark mode toggle (V1)

## MVP acceptance criteria
A user can:
1. Sign up, log in, work offline.
2. Create one area + two subjects.
3. Plan two sessions for today.
4. Start a Quick Start session, lock the phone for 30 minutes, return, complete it.
5. See the session in History.
6. See the dashboard updated with actual time + streak +1.
7. Kill the app, reopen — all data still there.
8. Reconnect to internet, see data appear in the backend.

## Non-goals for MVP
- Performance beyond "feels fast"
- Beautiful empty states (functional only)
- Onboarding tutorial
- Internationalization (English only)