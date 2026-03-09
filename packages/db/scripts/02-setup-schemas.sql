-- =============================================================================
-- Neon Schema Init — run as neondb_owner AFTER setup-roles.sql
-- Run once per environment (dev branch, then main).
--
-- Neon doesn't honour GRANT CREATE ON SCHEMA for directly-authenticated roles
-- (only works via SET ROLE from neondb_owner). db_manager_role must OWN the
-- schemas to have full DDL rights when logging in directly.
--   - GRANT db_manager_role TO neondb_owner allows the ownership transfer
--   - Prisma migrate's "CREATE SCHEMA IF NOT EXISTS" becomes a silent no-op
--   - internal schema is locked down from PUBLIC immediately
-- =============================================================================

-- Allow neondb_owner to transfer ownership to db_manager_role
GRANT db_manager_role TO neondb_owner;

CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS config;
CREATE SCHEMA IF NOT EXISTS usage;
CREATE SCHEMA IF NOT EXISTS ingested;
CREATE SCHEMA IF NOT EXISTS analytics;
CREATE SCHEMA IF NOT EXISTS internal;

-- Transfer ownership so db_manager_role has full DDL when logging in directly
ALTER SCHEMA core      OWNER TO db_manager_role;
ALTER SCHEMA config    OWNER TO db_manager_role;
ALTER SCHEMA usage     OWNER TO db_manager_role;
ALTER SCHEMA ingested  OWNER TO db_manager_role;
ALTER SCHEMA analytics OWNER TO db_manager_role;
ALTER SCHEMA internal  OWNER TO db_manager_role;

-- db_manager_role needs CONNECT + CREATE on the database for CREATE SCHEMA in migrations
GRANT CONNECT ON DATABASE areltools TO db_manager_role;
GRANT CREATE ON DATABASE areltools TO db_manager_role;

-- public schema: db_manager_role needs CREATE for Prisma's _prisma_migrations table
GRANT CREATE ON SCHEMA public TO db_manager_role;

-- Lock down internal from PUBLIC
REVOKE ALL ON SCHEMA internal FROM PUBLIC;
