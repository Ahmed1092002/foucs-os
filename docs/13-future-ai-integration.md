# 13 · Future AI Integration

> **AI is OUT of V1 and V2.**
> This document exists **only** to define the integration seams so the V1 architecture doesn't accidentally paint us into a corner.
> **No AI code, AI SDK, AI dependency, or AI route is permitted in V1 or V2.** Adding any of these requires an explicit architecture change-review.

## Goal
Let future AI services analyze historical learning data and surface gentle, personalized insights — without ever becoming a hard dependency of the core app.

## Architectural principle
```
Core app ──► AI Gateway (adapter) ──► Provider A | Provider B | Provider C
              (replaces easily)
```

- The AI layer is a **separate backend service** (or a module behind a feature flag).
- Core code never imports an LLM SDK.
- Prompts are **versioned templates**, not scattered string literals.

## Where the seams already exist in V1

| Seam | What V1 already collects | What AI will use it for |
|------|--------------------------|--------------------------|
| `study_sessions` | subject, topic, planned/actual, goal text + result, focus/energy ratings, notes, timestamps | Pattern detection: best time of day, best subject, focus correlation with subject |
| `subjects` | target hours, status, priority, deadline | Imbalance detection, deadline risk |
| `daily_plans` | planned day shape | Plan realism vs actual capacity |
| `daily_reviews` (V1) | mood/energy/free text | Mood correlation with output |
| `users.timezone` | IANA timezone | Localized insights |
| Aggregations already in `/stats/*` | streak, totals, per-subject | Feeds prompts cheaply without re-scanning raw rows |

## Module boundaries (when we add it in V3+)
```
backend/src/ai/
├── ai.module.ts                # only imported when AI_ENABLED=true
├── ai.controller.ts            # /api/v1/ai/insights (read-only for app)
├── insights/
│   ├── insight.types.ts        # Insight = {code, severity, message, suggestedAction}
│   ├── insight.engine.ts       # pure: inputs → list of insights
│   └── rules/                  # deterministic rules first (no LLM)
│       ├── missedSubjectRule.ts
│       ├── overloadRule.ts
│       └── streakRiskRule.ts
├── prompts/                    # versioned .md templates
│   ├── v1/weekly-digest.md
│   └── v1/load-balance.md
└── providers/
    ├── ai-provider.interface.ts
    ├── openai.provider.ts
    ├── anthropic.provider.ts
    └── mock.provider.ts        # tests + local dev
```

**Rules-first, LLM-second.** The first insights are deterministic (you haven't touched Databases in 5 days). The LLM is only used to summarize and humanize text, never to make decisions.

## What AI will (eventually) do
- Weekly digest: "Your strongest day was Tuesday (avg 2h 10m). Wednesdays have been under 1h for 3 weeks."
- Workload balancer: "You planned 18h this week but averaged 12h. Trim Thursday."
- Subject gap detection: "DevOps consistent, Databases stale."
- Session quality hint: "Sessions where you rated focus ≤ 2 also tend to end early."

## What AI will NOT do
- Edit user data automatically.
- Replace the deterministic streak / stats logic.
- Run on-device in V1.
- Be required for the app to function.

## Triggering
- Nightly cron (server) generates insights for active users.
- App pulls `/api/v1/ai/insights` like any other read endpoint.
- User can disable AI entirely in settings.

## Cost & privacy controls (V2 design)
- LLM only sees **aggregated** data by default; raw notes are opt-in.
- Per-user kill switch + audit log.
- Provider is abstracted behind `AIProvider` so we can swap OpenAI ↔ Anthropic ↔ local without touching the app.

## V1 guardrails (already in place)
- No AI module exists in `backend/src/`.
- No AI SDK in `package.json` or `pubspec.yaml`.
- API surface has no `/ai/*` routes.
- This doc is the only place "AI" appears in source-controlled planning.