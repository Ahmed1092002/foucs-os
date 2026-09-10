# 03 · User Flows

> Each flow is shown as plain steps + a tiny ASCII map.
> The product is offline-first, so every flow must work **without network**.

## Flow 1 · First-time onboarding
```
Sign up → Set timezone → Choose initial area → Add first subject
   │                                                    │
   └──────────► landed on Dashboard ◄───────────────────┘
```

## Flow 2 · Daily hero flow (the main one)
```
Dashboard
   │  sees today's plan
   ▼
Tap a planned subject
   │  → subject detail
   ▼
Press START
   │  → "60 min on React? useEffect?"
   ▼
Timer screen (focus mode)
   │  ▶ ticking
   │  (lock screen, leave app, return — still ticking correctly)
   ▼
Tap DONE
   │  → session summary
   ▼
"Yes, completed" + note + energy 4 + focus 5
   │  → saved locally
   │  → enqueued for sync
   ▼
Back to Dashboard (plan updated, streak updated)
```

## Flow 3 · Quick Start (no plan)
```
Bottom nav: tap "Quick Start"
   ▼
Choose subject  →  choose duration preset (25/30/45/60/90/120/custom)
   ▼
(optional) topic + goal
   ▼
START
   │
   └── same Timer screen as Flow 2
```

## Flow 4 · Planning tomorrow
```
Planner tab → pick date
   ▼
Add item: 09:00, React, 60 min
Add item: 10:15, DevOps, 90 min
Add item: 11:30, English, 30 min
   │
   ▼  total = 3h → green
   │   total = 9h → yellow warning
   │   total >12h → red warning + suggestion
   ▼
Save
```

## Flow 5 · Evening: Daily Review
```
Dashboard → "End of day" banner → tap
   ▼
Auto-summary: planned 3h, actual 2h 15m
   ▼
Rate productivity / energy / focus 1–5
   ▼
Notes: "what went well", "what blocked you"
   ▼
Save review → appears in History & Stats
```

## Flow 6 · Catch up after going offline
```
In a tunnel / no signal
   ▼
Start, pause, complete 2 sessions
   ▼
App stores them locally with `syncStatus = pending`
   ▼
Connection returns
   ▼
Sync worker pushes queued items
   ▼
Dashboard updates only if server has newer data (LWW for non-additive fields)
```

## Flow 7 · Background session reliability
```
User taps START at 09:00:00
   │
   ▼
Timer service stores {startedAt: 09:00:00}
   ▼
UI ticks locally every second for display only
   ▼
User locks phone at 09:05:00, unlocks at 09:47:00
   ▼
UI recomputes: now(09:47) − startedAt(09:00) − totalPausedMs
   │
   ▼
Actual = 42 min (never drifts)
```