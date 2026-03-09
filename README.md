<img align="right" src="docs/init/arel-logo-512.svg" width="108" />

<h1>Arel · Tools</h1>
<p><strong>Raid Lead Tools &mdash; Less admin, more action.</strong></p>
<p>One connected system &mdash; from the calendar to the pull. Arel handles scheduling, signups, roster management, encounter planning, and attendance tracking for World of Warcraft guilds.</p>
<p>The name is a phonetic homonym for R.L. &mdash; Raid Lead.</p>

---

## What it does

**Scheduling & Signup** — Post the raid night. Raiders sign up via Discord or web. Reminders go out automatically.

**Roster** — Signups populate your roster. Adjust roles, swap benches, confirm your 20.

**Encounter Planning** — Share the strat and assign individual roles before the pull. Accessible on the web and in-game via addon.

**Attendance** — Tracked via WCL logs. History stays on each raider. Next week starts where this one left off.

---

## How it works

1. Schedule the raid and collect signups
2. Set the roster
3. Plan encounters
4. Pull. Track. Repeat.

---

## Model

Free up to 8 raids per month. Patreon supporters unlock unlimited raids, scheduling automation, and early access to new features.

This is a passion project — built by one raider for the community.

---

## Stack

Monorepo — pnpm + Turborepo.

| Package / App | Purpose |
|---|---|
| `apps/app` | Main web app (Next.js) |
| `apps/admin` | Internal admin panel (Next.js) |
| `apps/api` | tRPC API server |
| `apps/bot` | Discord bot |
| `apps/www` | Marketing site (Astro) |
| `packages/db` | Prisma schema + migrations (Neon) |
| `packages/trpc` | tRPC router and procedures |
| `packages/auth` | Auth utilities |
| `packages/ui` | Shared component library |
| `packages/types` | Shared TypeScript types |
| `packages/config` | Shared config |
| `packages/utils` | Shared utilities |

---

## Getting started

```bash
pnpm install
cp .env.example .env
# Fill in .env — see .env.example for required vars
pnpm dev
```

Database setup:

```bash
cd packages/db
cp .env.example .env
# Fill in DB connection strings
pnpm db:migrate
```

---

## Out of scope

Loot systems — complex and nuanced enough to warrant their own tools. Pair Arel with [Gargul](https://github.com/papa-smurf/Gargul) and [SoftRes.it](https://softres.it).
