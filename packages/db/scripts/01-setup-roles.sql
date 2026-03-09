-- =============================================================================
-- Neon DB Role Setup — run once per environment (dev branch, then main)
-- NOT tracked by Prisma migrate — roles are cluster-level, not schema-level
--
-- Execution order:
--   1. 01-setup-roles.sql          (this file)    as neondb_owner  — create roles
--   2. 02-setup-schemas.sql                       as neondb_owner  — create schemas, grant CREATE to db_manager_role
--   3. 03-setup-grants-init.sql                   as neondb_owner  — USAGE grants for app_role / admin_role
--   4. 04-setup-default-privs.sql                 as db_manager_role — ALTER DEFAULT PRIVILEGES (covers all future tables)
--   5. [run migrations]                           as db_manager_role — creates tables; DML grants inherited automatically
-- =============================================================================

-- Create roles (idempotent — safe to re-run if roles already exist)
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_role') THEN
    CREATE ROLE app_role NOINHERIT LOGIN PASSWORD '<generate>';
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'admin_role') THEN
    CREATE ROLE admin_role NOINHERIT LOGIN PASSWORD '<generate>' BYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'db_manager_role') THEN
    CREATE ROLE db_manager_role NOINHERIT LOGIN PASSWORD '<generate>';
  END IF;
END
$$;
