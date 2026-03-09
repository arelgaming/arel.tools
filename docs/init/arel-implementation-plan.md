# Arel — Implementation Plan

## Status: Ready to build

Architecture is locked. Two pre-implementation blockers must be resolved in Week 1 before any migration work starts. Everything else can proceed in parallel once the repo scaffold is up.

---

## Pre-flight (Before writing any code)

Resolve both blockers first — they affect schema decisions.

| Blocker | Action | Est. time |
|---|---|---|
| **TimescaleDB on Neon** | Create a free Neon project, run `CREATE EXTENSION timescaledb;`, confirm it works on your target plan/region | 30 min |
| **WCL credentials model** | Check WCL API docs: can public reports be fetched with a platform-level API key, or does each guild need OAuth? | 1–2 hrs |

If TimescaleDB is unavailable: swap `usage_events` and `analytics` tables to native Postgres declarative partitioning before writing any migrations. The schema shape is the same; the `CREATE TABLE` syntax differs.

---

## Phase 1 goals

Get to: one running process (api + bot + worker), Postgres schema migrated, Discord login working, one real tRPC procedure end-to-end.

Not in Phase 1: Admin UI, Patreon integration, WCL sync, usage limits UI, full feature flag system. Infrastructure first, product second.

---

## Step 1 — Repo scaffold

### Use the official Turborepo starter, then gut it

Don't start from scratch. Turborepo's `create-turbo` gives you workspace config, `turbo.json`, and package linking wiring correctly out of the box. Starting from scratch means 2–4 hours of fiddling with workspace symlinks and build pipeline config that the starter handles automatically.

```bash
npx create-turbo@latest arel --package-manager pnpm
cd arel
```

The default starter ships with `apps/web`, `apps/docs`, and `packages/ui`, `packages/eslint-config`, `packages/typescript-config`. Use it as the skeleton — rename and add from there.

### What to keep from the starter
- `turbo.json` — edit the pipeline, don't rewrite it
- `packages/eslint-config` — extend with your import boundary rules
- `packages/typescript-config` — extend with your path aliases
- Root `package.json` workspace config

### What to replace/add

```
# Rename
apps/web   → apps/app      (Next.js 15)
apps/docs  → delete, reinit as apps/www (Astro)

# Add
apps/api                   (tRPC standalone — plain Node, not Next.js)
apps/bot                   (Discord.js)
apps/admin                 (Next.js — stub only in Phase 1)

# Add packages
packages/db                (Prisma — empty schema to start)
packages/trpc              (router skeleton)
packages/auth              (NextAuth configs)
packages/config            (feature/plan/limit resolution — stub to start)
packages/types             (shared TS types)
packages/utils             (shared utilities)

# Keep and extend
packages/ui                (add Arel brand tokens, shadcn setup)
packages/eslint-config     (add eslint-plugin-import boundary rules)
packages/typescript-config (add path aliases)
```

### ESLint import boundary rule — set up immediately

This is an architectural rule the doc enforces via lint. Add it before anyone writes code — it's much harder to retrofit after violations accumulate.

```bash
pnpm add -D eslint-plugin-import -w
```

In `packages/eslint-config`, add a rule that fails the build if anything other than `apps/api` imports from `packages/db`. The rule pattern varies by ESLint plugin version but the intent is: `packages/db` is a restricted import path for all workspaces except `apps/api`.

---

## Step 2 — External services

Get credentials before writing infrastructure code. All free tiers in Phase 1.

| Service | Action | Notes |
|---|---|---|
| **Neon** | Create project, get `DATABASE_URL` + `DATABASE_DIRECT_URL` | Both are required — pooled for runtime, direct for migrations. Create a `dev` branch immediately. |
| **Upstash Redis** | Create database, get REST URL + token | Free tier (10k req/day) is sufficient for Phase 1. |
| **Discord** | Create two Applications: `Arel (prod)` and `Arel (dev)` | Client ID, client secret, bot token for each. Install the dev bot into a test server. |
| **Flagsmith** | Create account and project, get SDK key | Cloud free tier for Phase 1. |
| **Inngest** | Create account, get signing key | Free dev tier. |
| **Vercel** | Create account, link repo | Hobby tier for Phase 1. |
| **Railway or Fly.io** | Create account | For the Phase 1 single-process container. Railway has simpler DX; Fly has more control. |

Create `.env.example` at the repo root and in each app that needs secrets. Never commit real values.

---

## Step 3 — Database schema (`packages/db`)

### Prisma setup

```bash
cd packages/db
pnpm add prisma @prisma/client
npx prisma init
```

Prisma supports multiple Postgres schemas via the `multiSchema` preview feature (note: as of early 2026 this feature is deprecated — use native schema support or raw SQL migrations for `internal.*` tables instead).

```prisma
// packages/db/prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider  = "postgresql"
  url       = env("DATABASE_URL")
  directUrl = env("DATABASE_DIRECT_URL")
}
```

**Two Postgres roles required** — `app_role` (guild ops, RLS enforced) and `admin_role` (admin ops, BYPASSRLS). See `docs/decisions/001-db-role-separation.md` for the full decision record and `packages/db/scripts/setup-roles.sql` for the one-time Neon setup script.

### Migration order

Write migrations in stages — each stage is independently testable before moving on.

**Stage A — Core identity (unblocks everything)**
1. `core.users`
2. `core.guilds` (including activity columns + data visibility columns)
3. `core.guild_members`
4. `core.subscriptions`

**Stage B — Access control**
5. `core.guild_role_mappings`
6. `core.guild_seats`
7. `config.service_tokens`

**Stage C — Config seed data**
8. `config.subscription_plans` + seed (`free`, `supporter`)
9. `config.feature_groups` + seed (the three-level hierarchy)
10. `config.features` + seed (initial GA features)
11. `config.plan_limits` + seed (`RAID_EVENTS_PER_MONTH`: free=8, supporter=null)
12. `config.plan_benefits` + seed (`DATA_VISIBILITY_DAYS`: free=30, supporter=null)
13. `config.bot_config`

**Stage D — Audit + integrations**
14. `core.guild_integrations`
15. `core.user_integrations`
16. `core.guild_audit_log`
17. `internal.audit_log`
18. `internal.archived_guilds`

**Stage E — Supporter model**
19. `core.supporter_links` (with partial unique index on `effective_month`)

**Stage F — Usage tracking** *(depends on TimescaleDB pre-flight result)*
20. `usage.usage_events` (hypertable or declarative partitioned table)
21. `usage.usage_history`
22. `config.guild_config_overrides`

**Stage G — Ingested data**
23. `ingested.wcl_reports`
24. `ingested.wcl_attendance` — include `UNIQUE (guild_id, wcl_report_id, player_name)` 
25. `ingested.wcl_kills`

**Stage H — Analytics** *(not needed for MVP)*
26. `analytics.events`, `analytics.bot_commands`, `analytics.api_call_log`

### RLS setup

After Stage A migrations, add RLS policies. These are raw SQL — write them as a standalone migration file (`migration.sql`) that Prisma won't overwrite:

```sql
ALTER TABLE core.guilds ENABLE ROW LEVEL SECURITY;
CREATE POLICY guild_isolation ON core.guilds
  USING (guild_id = current_setting('app.current_guild_id', true));
-- Repeat for every guild-scoped table
```

The Prisma `$extends` client extension that injects `SET LOCAL app.current_guild_id` per request lives in `packages/db/src/client.ts`. The context factory in `apps/api` wraps every request in a `$transaction` and calls it before any query runs.

---

## Step 4 — API service (`apps/api`)

`apps/api` is a plain Node.js HTTP server — not Next.js. Use `@trpc/server` with an Express or Fastify adapter.

```bash
cd apps/api
pnpm add @trpc/server express zod
pnpm add -D @types/express tsx
```

### Build order

1. **Context factory** — the most critical file. Resolves `serviceRole`, `guildId`, `userId`, wraps DB in the RLS transaction. Everything else depends on this being correct.
2. **`baseProcedure`** — service role check only
3. **`guildProcedure`** → **`memberProcedure`** → **`raidManagerProcedure`** → **`guildAdminProcedure`**
4. **`workerProcedure`** and **`internalAdminProcedure`**
5. **Bot procedure hierarchy** — `botProcedure` → `botUserProcedure` → etc.
6. First real router: `guilds` — enough to test the full stack end-to-end

### `packages/trpc` vs `apps/api`

- `packages/trpc` holds router type exports, middleware definitions, shared procedure builders
- `apps/api` holds actual procedure implementations and the HTTP server entrypoint

The web app imports types only from `packages/trpc` — never from `apps/api` directly.

---

## Step 5 — Auth (`packages/auth` + `apps/app`)

```bash
cd apps/app
pnpm add next-auth@beta
```

NextAuth v5 config in `packages/auth/src/discord.ts`. Session shape is defined in the architecture doc — `userId`, `discordId`, `activeGuildId`, `guilds[]`. `arelRole` is NOT stored in the JWT.

Critical config detail: set the session cookie on `.arel.tools` root domain so the marketing site can read it:

```typescript
cookies: {
  sessionToken: {
    options: { domain: '.arel.tools' }
  }
}
```

### Permission cache

Implement `cache:permissions:{userId}:{guildId}` in Redis early — everything depends on it. Resolution order:
1. Check `core.guild_seats` for GUILD_ADMIN
2. Check `core.guild_seats` for RAID_MANAGER
3. Check Discord roles against `core.guild_role_mappings` for MEMBER
4. Return null (no role)

Cache with 5-min TTL. Bust immediately on seat grant/revoke, role mapping change, or `GUILD_MEMBER_UPDATE` from the bot.

---

## Step 6 — Bot (`apps/bot`)

```bash
cd apps/bot
pnpm add discord.js
```

### Phase 1 in-process wiring

In Phase 1, `apps/bot` calls tRPC procedures as direct function imports — no HTTP. Wire a conditional in the bot entrypoint:

```typescript
// If TRPC_API_URL is set → HTTP client (Phase 2)
// If not set → in-process function calls (Phase 1)
```

This is the only code change needed when splitting to Phase 2.

### Build order

1. Gateway connection + basic event handler
2. `GUILD_MEMBER_UPDATE` handler — drives permission cache invalidation; the whole access control system depends on it
3. Slash command registration against the dev Discord Application
4. First slash command — something read-only (e.g. `/roster`) to test the full bot → API → DB → response path
5. `MESSAGE_CREATE` handler for WCL URL detection — can come later

---

## Step 7 — `packages/config`

Stub this early so the middleware compiles; fill in real logic once the DB schema is in place.

Build order:
1. `canAccessFeature(guild, featureId)` — stub returns `true` for now
2. `isPlanEligible(guild, featureId)` — DB group walk, Redis cached
3. Flagsmith integration — `flagsmith.isEnabled(featureId, guildId)`
4. `requireFeature(featureId)` tRPC middleware
5. `requireLimit(limitType)` tRPC middleware — DB transaction with `SELECT ... FOR UPDATE`

---

## Step 8 — Phase 1 single-process entrypoint

```typescript
// apps/api/src/index.ts  — Phase 1: api + bot + inngest in one process
import { startBot } from '../../bot/src/index'
import { inngestHandler } from './inngest'
import { createServer } from './server'

const app = createServer()
app.use('/api/inngest', inngestHandler)
app.listen(3001)

startBot({ trpc: inProcessCaller })
```

```typescript
// apps/api/src/server.ts  — Phase 2: api only (reused by both entrypoints)
```

The `inProcessCaller` is a tRPC `createCallerFactory` instance — same procedure definitions, no HTTP.

---

## Step 9 — First deployment

**Target: one Railway/Fly container + Vercel hobby**

1. `Dockerfile` at repo root — builds the monorepo with Turborepo's `--filter` flag:
   ```dockerfile
   RUN pnpm turbo build --filter=api...
   # The ... includes all dependency packages automatically
   ```
2. Vercel: connect repo, set root directory to `apps/app`, add env vars
3. Railway/Fly: connect repo, point at Dockerfile, set env vars
4. Neon: run `prisma migrate deploy` against `dev` branch manually to validate, then `main`

### GitHub Actions — set up early

Even in Phase 1, configure:
- Neon branch create/delete on PR open/close
- `prisma migrate deploy` against the PR branch at preview deploy time
- CI: typecheck + lint on every PR

---

## Step 10 — First product feature: Guild onboarding

The first real user-facing feature, in order:

1. Bot OAuth install flow → redirect to `app.arel.tools/setup`
2. Write `core.guilds` + `core.subscriptions` (plan: `free`) on first login
3. Grant first GUILD_ADMIN seat via admin UI — manual engineering action at this stage
4. Guild dashboard renders, even if mostly empty
5. Role mappings UI — guild admin maps Discord roles to Arel roles
6. Raid event creation with `RAID_EVENTS_PER_MONTH` limit enforcement

---

## Dependency map

```
Pre-flight (TimescaleDB + WCL)
  └── Schema Stage A (core identity)
        ├── Context factory + RLS
        │     ├── Procedure hierarchy
        │     │     ├── Discord OAuth (auth)
        │     │     ├── Bot gateway + GUILD_MEMBER_UPDATE
        │     │     └── First real router (guilds)
        │     └── Permission cache (Redis)
        └── Schema Stage B–C (seed data)
              └── packages/config stubs → real logic
                    └── Usage limit enforcement
                          └── Raid event creation (first product feature)
```

---

## What stays out of Phase 1

- Admin UI beyond a single stub route
- Patreon OAuth + supporter links
- WCL sync (bot listener + Inngest job)
- Usage meter UI (enforce the limit, but no dashboard display yet)
- `data_visible_from.recalculate` cron
- Inactivity warning + archive crons
- Flagsmith rollout logic (integrate Flagsmith, but all flags default on for now)
- Analytics schema (Stage H)

---

## Decisions needed at kickoff

| Decision | Impact |
|---|---|
| TimescaleDB available on Neon? | Blocks Stage F migration syntax |
| WCL public API key sufficient? | Affects Stage G schema + onboarding flow |
| Railway or Fly.io for Phase 1? | Dockerfile and deploy config |
| Who handles first GUILD_ADMIN manual grants during dev? | Needs a named person |
| pnpm version to pin? | Turborepo is sensitive to this — lock it in `packageManager` in root `package.json` |
