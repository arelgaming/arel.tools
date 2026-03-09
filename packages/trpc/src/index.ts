import { initTRPC, TRPCError } from "@trpc/server";
import { adminPrisma, type withGuildContext } from "@repo/db";
import type { ServiceRole } from "@repo/types";
import { resolveArelRole } from "./permissions.js";

export type { ArelPermission } from "./permissions.js";

export type Context =
  | {
      db: ReturnType<typeof withGuildContext>;
      guildId: string;
      serviceRole: ServiceRole;
      userId: string | null;
    }
  | {
      db: null;
      guildId: null;
      serviceRole: null;
      userId: null;
    };

const t = initTRPC.context<Context>().create();

export const router = t.router;
export const publicProcedure = t.procedure;

// ─── protectedProcedure ──────────────────────────────────────────────────────
// Requires a valid service token (non-null guild context).

export const protectedProcedure = t.procedure.use(({ ctx, next }) => {
  if (!ctx.guildId || !ctx.serviceRole) {
    throw new TRPCError({ code: "UNAUTHORIZED" });
  }
  return next({
    ctx: {
      db: ctx.db,
      guildId: ctx.guildId,
      serviceRole: ctx.serviceRole,
      userId: ctx.userId,
    },
  });
});

// ─── userProcedure ───────────────────────────────────────────────────────────
// Any serviceRole — userId must be present.

export const userProcedure = protectedProcedure.use(({ ctx, next }) => {
  if (!ctx.userId) {
    throw new TRPCError({ code: "UNAUTHORIZED" });
  }
  return next({ ctx: { ...ctx, userId: ctx.userId } });
});

// ─── memberProcedure ─────────────────────────────────────────────────────────
// Requires userId + resolved ArelRole >= MEMBER.

export const memberProcedure = userProcedure.use(async ({ ctx, next }) => {
  const permission = await resolveArelRole(ctx.db, ctx.guildId, ctx.userId);
  if (!permission) {
    throw new TRPCError({ code: "FORBIDDEN" });
  }
  return next({ ctx: { ...ctx, permission } });
});

// ─── raidManagerProcedure ────────────────────────────────────────────────────
// Requires userId + ArelRole >= RAID_MANAGER.
// Extends userProcedure directly (not memberProcedure) to cap chain depth.

export const raidManagerProcedure = userProcedure.use(async ({ ctx, next }) => {
  const permission = await resolveArelRole(ctx.db, ctx.guildId, ctx.userId);
  if (!permission || permission === "MEMBER") {
    throw new TRPCError({ code: "FORBIDDEN" });
  }
  return next({ ctx: { ...ctx, permission } });
});

// ─── guildAdminProcedure ─────────────────────────────────────────────────────
// Requires userId + ArelRole === GUILD_ADMIN.
// Extends userProcedure directly to cap chain depth.

export const guildAdminProcedure = userProcedure.use(async ({ ctx, next }) => {
  const permission = await resolveArelRole(ctx.db, ctx.guildId, ctx.userId);
  if (permission !== "GUILD_ADMIN") {
    throw new TRPCError({ code: "FORBIDDEN" });
  }
  return next({ ctx: { ...ctx, permission } });
});

// ─── botProcedure ────────────────────────────────────────────────────────────
// Requires serviceRole === "bot".

export const botProcedure = protectedProcedure.use(({ ctx, next }) => {
  if (ctx.serviceRole !== "bot") {
    throw new TRPCError({ code: "FORBIDDEN" });
  }
  return next({ ctx });
});

// ─── botUserProcedure ────────────────────────────────────────────────────────
// Bot caller + userId present.

export const botUserProcedure = botProcedure.use(({ ctx, next }) => {
  if (!ctx.userId) {
    throw new TRPCError({ code: "UNAUTHORIZED" });
  }
  return next({ ctx: { ...ctx, userId: ctx.userId } });
});

// ─── botMemberProcedure ──────────────────────────────────────────────────────
// Bot caller + userId + ArelRole >= MEMBER.
// Extends botProcedure directly to cap chain depth.

export const botMemberProcedure = botProcedure.use(async ({ ctx, next }) => {
  if (!ctx.userId) {
    throw new TRPCError({ code: "UNAUTHORIZED" });
  }
  const permission = await resolveArelRole(ctx.db, ctx.guildId, ctx.userId);
  if (!permission) {
    throw new TRPCError({ code: "FORBIDDEN" });
  }
  return next({ ctx: { ...ctx, userId: ctx.userId, permission } });
});

// ─── botRaidManagerProcedure ─────────────────────────────────────────────────
// Bot caller + ArelRole >= RAID_MANAGER.
// Extends botProcedure directly to cap chain depth.

export const botRaidManagerProcedure = botProcedure.use(async ({ ctx, next }) => {
  if (!ctx.userId) {
    throw new TRPCError({ code: "UNAUTHORIZED" });
  }
  const permission = await resolveArelRole(ctx.db, ctx.guildId, ctx.userId);
  if (!permission || permission === "MEMBER") {
    throw new TRPCError({ code: "FORBIDDEN" });
  }
  return next({ ctx: { ...ctx, userId: ctx.userId, permission } });
});

// ─── botGuildAdminProcedure ──────────────────────────────────────────────────
// Bot caller + ArelRole === GUILD_ADMIN.
// Extends botProcedure directly to cap chain depth.

export const botGuildAdminProcedure = botProcedure.use(async ({ ctx, next }) => {
  if (!ctx.userId) {
    throw new TRPCError({ code: "UNAUTHORIZED" });
  }
  const permission = await resolveArelRole(ctx.db, ctx.guildId, ctx.userId);
  if (permission !== "GUILD_ADMIN") {
    throw new TRPCError({ code: "FORBIDDEN" });
  }
  return next({ ctx: { ...ctx, userId: ctx.userId, permission } });
});

// ─── workerProcedure ─────────────────────────────────────────────────────────
// Inngest / background jobs — serviceRole === "worker".

export const workerProcedure = protectedProcedure.use(({ ctx, next }) => {
  if (ctx.serviceRole !== "worker") {
    throw new TRPCError({ code: "FORBIDDEN" });
  }
  return next({ ctx });
});

// ─── internalAdminProcedure ──────────────────────────────────────────────────
// Internal Arel team Admin UI — serviceRole === "admin" + adminDb injected.

export const internalAdminProcedure = protectedProcedure.use(({ ctx, next }) => {
  if (ctx.serviceRole !== "admin") {
    throw new TRPCError({ code: "FORBIDDEN" });
  }
  return next({ ctx: { ...ctx, adminDb: adminPrisma } });
});
