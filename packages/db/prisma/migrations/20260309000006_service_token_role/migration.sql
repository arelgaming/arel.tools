CREATE TYPE "config"."ServiceRole" AS ENUM ('app', 'api', 'bot', 'www', 'admin');

ALTER TABLE "config"."service_tokens"
  ADD COLUMN "role" "config"."ServiceRole" NOT NULL;
