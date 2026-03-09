-- =============================================================================
-- Neon Schema Grants (init) — run as neondb_owner AFTER 02-setup-schemas.sql,
-- BEFORE running any Prisma migrations.
-- Run once per environment (dev branch, then main).
-- =============================================================================

-- app_role: guild schemas only, no internal
GRANT USAGE ON SCHEMA core, config, usage, ingested, analytics TO app_role;

-- admin_role: all schemas including internal
GRANT USAGE ON SCHEMA core, config, usage, ingested, analytics, internal TO admin_role;
