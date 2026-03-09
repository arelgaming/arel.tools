-- =============================================================================
-- Neon Default Privileges — run as db_manager_role AFTER 03-setup-grants-init.sql,
-- BEFORE running any Prisma migrations.
-- Run once per environment (dev branch, then main).
--
-- Must run as db_manager_role (not neondb_owner) — ALTER DEFAULT PRIVILEGES
-- only works for the current role or a superuser. No FOR ROLE clause needed
-- when running as the role itself.
-- =============================================================================

-- app_role (all schemas except internal)
ALTER DEFAULT PRIVILEGES IN SCHEMA core
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA config
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA usage
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA ingested
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA analytics
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_role;

-- admin_role (all schemas including internal)
ALTER DEFAULT PRIVILEGES IN SCHEMA core
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO admin_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA config
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO admin_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA usage
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO admin_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA ingested
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO admin_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA analytics
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO admin_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA internal
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO admin_role;
