# ADR 001 — DB Role Separation

**Status:** Accepted
**Date:** 2026-03-09

---

## Context

Arel uses a single Neon Postgres project with multiple schemas:

- Guild-facing schemas: `core`, `config`, `usage`, `ingested`, `analytics`
- Admin-only schemas: `internal` (audit log, admin users, archived guilds)

The `internal` schema contains sensitive operational data (admin audit trail, archived guild records) that must be unreachable from the credentials used by guild-facing application code. A single database credential would mean a bug or injection in guild-facing code could read or corrupt admin-only data.

---

## Decision

Two Postgres roles in the same Neon project, one database:

| Role | Purpose | RLS | Schemas |
|---|---|---|---|
| `app_role` | Guild queries, tRPC procedures | Enforced | `core`, `config`, `usage`, `ingested`, `analytics` |
| `admin_role` | Admin procedures only | `BYPASSRLS` | All schemas including `internal` |

Two Prisma client exports in `packages/db`:

- `prisma` — uses `DATABASE_URL` (app_role credentials)
- `adminPrisma` — uses `ADMIN_DATABASE_URL` (admin_role credentials)

`adminPrisma` is only imported in `internalAdminProcedure` handlers inside `apps/api`. The `adminDbBoundaryConfig` ESLint rule in `packages/eslint-config/boundaries.js` enforces this at the import level.

Role setup is a two-step manual process, not tracked by Prisma migrate:
1. `packages/db/scripts/setup-roles.sql` — creates the roles. Run before any migrations.
2. `packages/db/scripts/setup-grants.sql` — grants schema usage. Run after the first migration creates the schemas.

---

## Consequences

- **app_role** gets `GRANT USAGE` on guild schemas only. Table-level `SELECT/INSERT/UPDATE/DELETE` grants are added per-migration as models are added.
- **admin_role** gets `GRANT USAGE` on all schemas. Table-level grants added similarly.
- `REVOKE ALL ON SCHEMA internal FROM PUBLIC` ensures no other role can reach `internal.*` by accident.
- `setup-roles.sql` + `setup-grants.sql` must be re-run against each new Neon branch (e.g., when promoting dev → main).
- Developers must set both `DATABASE_URL` and `ADMIN_DATABASE_URL` in their local `.env`. See `.env.example`.
- Any new `internalAdminProcedure` handler that needs `adminPrisma` must import it from `@repo/db` directly (not via a re-export in a shared module), so the ESLint boundary rule catches misuse in other files.
