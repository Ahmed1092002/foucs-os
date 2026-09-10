# 05 · System Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                    MOBILE (Flutter · Android/iOS)                 │
│                                                                  │
│   ┌─────────┐   ┌──────────┐   ┌─────────────┐   ┌────────────┐  │
│   │  UI     │   │ Riverpod │   │ Repositories│   │  Drift DB  │  │
│   │ Widgets │◄─►│ Providers│◄─►│ (domain)    │◄─►│ (SQLite)   │  │
│   └─────────┘   └──────────┘   └──────┬──────┘   └────────────┘  │
│                                        │                          │
│                                        ▼                          │
│                              ┌──────────────────┐                 │
│                              │   Sync Service   │                 │
│                              │  (queue + push)  │                 │
│                              └────────┬─────────┘                 │
└───────────────────────────────────────┼──────────────────────────┘
                                        │ HTTPS · JWT
                                        ▼
┌──────────────────────────────────────────────────────────────────┐
│                    BACKEND (NestJS · Node.js)                    │
│                                                                  │
│   Controllers ─► Services ─► Repositories ─► Prisma ─► PostgreSQL│
│                                                                  │
│   Cross-cutting: Validation · Logging · Error filter · Auth guard│
└──────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
                            ┌────────────────────┐
                            │    PostgreSQL 16   │
                            └────────────────────┘
                                        ▲
                                        │ (future, NOT V1)
                            ┌────────────┴───────────┐
                            │   AI Service (V2+)    │
                            │   pluggable provider  │
                            └────────────────────────┘
```

## Layers & who builds them
| Layer | Tech | Responsibility |
|-------|------|----------------|
| UI | Flutter + Material 3 | Render, input, navigation |
| State | Riverpod 2 | Reactive state, providers |
| Domain | Dart classes | Pure business rules, no I/O |
| Data — Local | Drift (SQLite) | Source of truth on device |
| Data — Remote | Dio + JWT | Backend REST client |
| Sync | Custom service | Queue mutations, resolve conflicts |
| Backend | NestJS + Prisma | Auth, business logic, persistence |
| DB | PostgreSQL 16 | Authoritative store |
| Future AI | Adapter interface | Swappable LLM provider (V2+) |

## Why this shape
- **Drift (SQLite) on-device** → queries, joins, migrations, and the same SQL mindset as PostgreSQL later. (See [06 · Flutter](./06-flutter-architecture.md) for the Isar vs Drift trade-off.)
- **Local DB is source of truth on device**, backend is source of truth across devices.
- **Sync service** is the only thing that talks to the backend, so we can swap REST for GraphQL or gRPC later.
- **No AI in V1** — but the AI adapter is a placeholder in the architecture diagram so we don't paint ourselves into a corner.

## Environment matrix
| Env | DB | Backend | Notes |
|-----|----|---------| -------|
| Local dev | Postgres in Docker | `npm run start:dev` | Hot reload |
| Tests | Postgres in Docker (test container) | `npm run test:e2e` | Fresh DB per suite |
| Mobile dev | Drift only (offline) | Optional local backend | Default = offline |
| Staging | Managed Postgres | Cloud Run / Fly.io | TBD |
| Prod | Managed Postgres | Cloud Run / Fly.io | TBD |

## Security
- JWT access (15 min) + refresh token (30 days, rotated).
- Passwords hashed with **bcrypt** (cost 12).
- All endpoints behind `JwtAuthGuard` except `/auth/*`.
- HTTPS only in production.
- Per-row scoping: every query filters by `userId` from JWT.