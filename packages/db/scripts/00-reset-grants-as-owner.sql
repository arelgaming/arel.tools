-- =============================================================================
-- Reset Grants — run as neondb_owner to wipe schema-level grants.
-- Keeps roles intact. Safe to run multiple times.
-- Follow with 00-reset-default-privs-as-db-manager.sql, then re-run 01–04.
-- =============================================================================

-- Revoke schema USAGE from app_role and admin_role
REVOKE USAGE ON SCHEMA core, config, usage, ingested, analytics
  FROM app_role;
REVOKE USAGE ON SCHEMA core, config, usage, ingested, analytics, internal
  FROM admin_role;

-- Transfer schema ownership back to neondb_owner
ALTER SCHEMA core      OWNER TO neondb_owner;
ALTER SCHEMA config    OWNER TO neondb_owner;
ALTER SCHEMA usage     OWNER TO neondb_owner;
ALTER SCHEMA ingested  OWNER TO neondb_owner;
ALTER SCHEMA analytics OWNER TO neondb_owner;
ALTER SCHEMA internal  OWNER TO neondb_owner;

-- Revoke database access from db_manager_role
REVOKE CONNECT, CREATE ON DATABASE areltools FROM db_manager_role;
REVOKE CREATE ON SCHEMA public FROM db_manager_role;

-- Revoke any table-level DML that may have been granted directly
REVOKE ALL ON ALL TABLES IN SCHEMA core FROM app_role;
REVOKE ALL ON ALL TABLES IN SCHEMA core FROM admin_role;
