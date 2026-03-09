-- CreateEnum
CREATE TYPE "core"."ArelRole" AS ENUM ('MEMBER', 'RAID_MANAGER');

-- CreateEnum
CREATE TYPE "core"."SeatType" AS ENUM ('GUILD_ADMIN', 'RAID_MANAGER');

-- CreateTable
CREATE TABLE "core"."guild_role_mappings" (
    "guild_id" TEXT NOT NULL,
    "discord_role_id" TEXT NOT NULL,
    "arel_role" "core"."ArelRole" NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "guild_role_mappings_pkey" PRIMARY KEY ("guild_id","discord_role_id")
);

-- CreateTable
CREATE TABLE "core"."guild_seats" (
    "guild_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "seat_type" "core"."SeatType" NOT NULL,
    "granted_by" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "guild_seats_pkey" PRIMARY KEY ("guild_id","user_id")
);

-- CreateTable
CREATE TABLE "config"."service_tokens" (
    "id" TEXT NOT NULL,
    "guild_id" TEXT NOT NULL,
    "token_hash" TEXT NOT NULL,
    "label" TEXT NOT NULL,
    "created_by" TEXT NOT NULL,
    "last_used_at" TIMESTAMP(3),
    "expires_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "service_tokens_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "core"."guild_role_mappings" ADD CONSTRAINT "guild_role_mappings_guild_id_fkey" FOREIGN KEY ("guild_id") REFERENCES "core"."guilds"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "core"."guild_seats" ADD CONSTRAINT "guild_seats_guild_id_fkey" FOREIGN KEY ("guild_id") REFERENCES "core"."guilds"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "core"."guild_seats" ADD CONSTRAINT "guild_seats_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "core"."users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "core"."guild_seats" ADD CONSTRAINT "guild_seats_granted_by_fkey" FOREIGN KEY ("granted_by") REFERENCES "core"."users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "config"."service_tokens" ADD CONSTRAINT "service_tokens_guild_id_fkey" FOREIGN KEY ("guild_id") REFERENCES "core"."guilds"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "config"."service_tokens" ADD CONSTRAINT "service_tokens_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "core"."users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- EnableRLS: guild-scoped tables
ALTER TABLE core.guild_role_mappings ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.guild_seats ENABLE ROW LEVEL SECURITY;
ALTER TABLE config.service_tokens ENABLE ROW LEVEL SECURITY;

-- RLS: guild_isolation policies
CREATE POLICY guild_isolation ON core.guild_role_mappings
  USING (guild_id = current_setting('app.current_guild_id', true));

CREATE POLICY guild_isolation ON core.guild_seats
  USING (guild_id = current_setting('app.current_guild_id', true));

CREATE POLICY guild_isolation ON config.service_tokens
  USING (guild_id = current_setting('app.current_guild_id', true));
