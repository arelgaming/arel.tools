-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "core";

-- CreateTable
CREATE TABLE "core"."users" (
    "id" TEXT NOT NULL,
    "discord_id" TEXT NOT NULL,
    "discord_username" TEXT NOT NULL,
    "discord_avatar" TEXT,
    "patreon_member_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "core"."guilds" (
    "id" TEXT NOT NULL,
    "discord_guild_id" TEXT NOT NULL,
    "discord_name" TEXT NOT NULL,
    "discord_icon" TEXT,
    "owner_user_id" TEXT NOT NULL,
    "last_web_activity_at" TIMESTAMP(3),
    "last_bot_activity_at" TIMESTAMP(3),
    "last_raid_event_updated_at" TIMESTAMP(3),
    "last_plan_change_at" TIMESTAMP(3),
    "data_visible_from" TIMESTAMP(3),
    "has_older_data" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "guilds_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "core"."guild_members" (
    "guild_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "discord_roles" TEXT[],
    "joined_at" TIMESTAMP(3) NOT NULL,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "guild_members_pkey" PRIMARY KEY ("guild_id","user_id")
);

-- CreateTable
CREATE TABLE "core"."subscriptions" (
    "guild_id" TEXT NOT NULL,
    "plan_id" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'ACTIVE',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("guild_id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_discord_id_key" ON "core"."users"("discord_id");

-- CreateIndex
CREATE UNIQUE INDEX "users_patreon_member_id_key" ON "core"."users"("patreon_member_id");

-- CreateIndex
CREATE UNIQUE INDEX "guilds_discord_guild_id_key" ON "core"."guilds"("discord_guild_id");

-- AddForeignKey
ALTER TABLE "core"."guilds" ADD CONSTRAINT "guilds_owner_user_id_fkey" FOREIGN KEY ("owner_user_id") REFERENCES "core"."users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "core"."guild_members" ADD CONSTRAINT "guild_members_guild_id_fkey" FOREIGN KEY ("guild_id") REFERENCES "core"."guilds"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "core"."guild_members" ADD CONSTRAINT "guild_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "core"."users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "core"."subscriptions" ADD CONSTRAINT "subscriptions_guild_id_fkey" FOREIGN KEY ("guild_id") REFERENCES "core"."guilds"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddGeneratedColumn: last_activity_at (GENERATED ALWAYS AS STORED)
ALTER TABLE core.guilds
  ADD COLUMN last_activity_at timestamptz GENERATED ALWAYS AS (
    GREATEST(
      COALESCE(last_web_activity_at, created_at),
      COALESCE(last_bot_activity_at, created_at),
      COALESCE(last_raid_event_updated_at, created_at),
      COALESCE(last_plan_change_at, created_at)
    )
  ) STORED;
