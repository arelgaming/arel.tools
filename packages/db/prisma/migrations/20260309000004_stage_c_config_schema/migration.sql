-- CreateTable
CREATE TABLE "config"."subscription_plans" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "subscription_plans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "config"."feature_groups" (
    "id" TEXT NOT NULL,
    "parent_id" TEXT,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "feature_groups_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "config"."features" (
    "id" TEXT NOT NULL,
    "group_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "is_ga" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "features_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "config"."plan_limits" (
    "plan_id" TEXT NOT NULL,
    "limit_key" TEXT NOT NULL,
    "value" INTEGER,

    CONSTRAINT "plan_limits_pkey" PRIMARY KEY ("plan_id","limit_key")
);

-- CreateTable
CREATE TABLE "config"."plan_benefits" (
    "plan_id" TEXT NOT NULL,
    "benefit_key" TEXT NOT NULL,
    "value" INTEGER,

    CONSTRAINT "plan_benefits_pkey" PRIMARY KEY ("plan_id","benefit_key")
);

-- CreateTable
CREATE TABLE "config"."bot_config" (
    "guild_id" TEXT NOT NULL,
    "prefix" TEXT NOT NULL DEFAULT '!',
    "bot_enabled" BOOLEAN NOT NULL DEFAULT true,
    "announce_events" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "bot_config_pkey" PRIMARY KEY ("guild_id")
);

-- AddForeignKey: feature_groups self-reference
ALTER TABLE "config"."feature_groups" ADD CONSTRAINT "feature_groups_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "config"."feature_groups"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey: features -> feature_groups
ALTER TABLE "config"."features" ADD CONSTRAINT "features_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "config"."feature_groups"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey: plan_limits -> subscription_plans
ALTER TABLE "config"."plan_limits" ADD CONSTRAINT "plan_limits_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "config"."subscription_plans"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey: plan_benefits -> subscription_plans
ALTER TABLE "config"."plan_benefits" ADD CONSTRAINT "plan_benefits_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "config"."subscription_plans"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey: bot_config -> guilds
ALTER TABLE "config"."bot_config" ADD CONSTRAINT "bot_config_guild_id_fkey" FOREIGN KEY ("guild_id") REFERENCES "core"."guilds"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey: subscriptions.plan_id -> subscription_plans (wires Stage A FK)
ALTER TABLE "core"."subscriptions" ADD CONSTRAINT "subscriptions_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "config"."subscription_plans"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- EnableRLS: bot_config is guild-scoped
ALTER TABLE config.bot_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY guild_isolation ON config.bot_config
  USING (guild_id = current_setting('app.current_guild_id', true));
