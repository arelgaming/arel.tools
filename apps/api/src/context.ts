import { createHash } from "crypto";
import { prisma, withGuildContext } from "@repo/db";
import type { Context } from "@repo/trpc";
import type { CreateExpressContextOptions } from "@trpc/server/adapters/express";

export async function createContext({
  req,
}: CreateExpressContextOptions): Promise<Context> {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith("Bearer ")) return nullContext();

  const rawToken = authHeader.slice(7);
  const tokenHash = createHash("sha256").update(rawToken).digest("hex");

  const serviceToken = await prisma.serviceToken.findFirst({
    where: {
      token_hash: tokenHash,
      OR: [{ expires_at: null }, { expires_at: { gt: new Date() } }],
    },
  });

  if (!serviceToken) return nullContext();

  // Update last_used_at async — not on critical path
  void prisma.serviceToken.update({
    where: { id: serviceToken.id },
    data: { last_used_at: new Date() },
  });

  const userId = req.headers["x-user-id"];

  return {
    db: withGuildContext(serviceToken.guild_id),
    guildId: serviceToken.guild_id,
    serviceRole: serviceToken.role,
    userId: typeof userId === "string" ? userId : null,
  };
}

function nullContext(): Context {
  return { db: null, guildId: null, serviceRole: null, userId: null };
}
