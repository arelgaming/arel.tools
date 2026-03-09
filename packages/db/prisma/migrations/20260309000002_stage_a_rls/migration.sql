-- Enable RLS on all Stage A guild-scoped tables
ALTER TABLE core.guilds ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.guild_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.subscriptions ENABLE ROW LEVEL SECURITY;

-- Guild isolation policies
CREATE POLICY guild_isolation ON core.guilds
  USING (id = current_setting('app.current_guild_id', true));

CREATE POLICY guild_isolation ON core.guild_members
  USING (guild_id = current_setting('app.current_guild_id', true));

CREATE POLICY guild_isolation ON core.subscriptions
  USING (guild_id = current_setting('app.current_guild_id', true));

-- core.users is cross-cutting — no guild isolation policy
