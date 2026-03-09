-- Seed: subscription_plans
INSERT INTO config.subscription_plans (id, name) VALUES
  ('free',      'Free'),
  ('supporter', 'Supporter');

-- Seed: feature_groups (three-level hierarchy)
-- Level 1: top-level domains
INSERT INTO config.feature_groups (id, parent_id, name, description) VALUES
  ('raids',          NULL,    'Raids',          'Raid event management'),
  ('analytics',      NULL,    'Analytics',      'Data and reporting'),
  ('administration', NULL,    'Administration', 'Guild management');

-- Level 2: sub-domains
INSERT INTO config.feature_groups (id, parent_id, name, description) VALUES
  ('raids.scheduling',      'raids',          'Scheduling',     'Raid scheduling'),
  ('raids.composition',     'raids',          'Composition',    'Raid composition'),
  ('analytics.historical',  'analytics',      'Historical Data','Historical data access'),
  ('analytics.reporting',   'analytics',      'Reporting',      'Advanced reporting'),
  ('administration.access', 'administration', 'Access Control', 'Access control');

-- Level 3: leaf groups
INSERT INTO config.feature_groups (id, parent_id, name, description) VALUES
  ('raids.scheduling.recurring',       'raids.scheduling',     'Recurring Events',  'Recurring raid scheduling'),
  ('analytics.historical.extended',    'analytics.historical', 'Extended History',  'Extended data retention');

-- Seed: features (GA)
INSERT INTO config.features (id, group_id, name, is_ga) VALUES
  ('feature_raid_events',    'raids.scheduling',     'Raid Events',    true),
  ('feature_data_visibility','analytics.historical', 'Data Visibility',true);

-- Seed: plan_limits
-- null value = unlimited
INSERT INTO config.plan_limits (plan_id, limit_key, value) VALUES
  ('free',      'RAID_EVENTS_PER_MONTH', 8),
  ('supporter', 'RAID_EVENTS_PER_MONTH', NULL);

-- Seed: plan_benefits
-- null value = unlimited
INSERT INTO config.plan_benefits (plan_id, benefit_key, value) VALUES
  ('free',      'DATA_VISIBILITY_DAYS', 30),
  ('supporter', 'DATA_VISIBILITY_DAYS', NULL);
