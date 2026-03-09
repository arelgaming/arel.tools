import type { withGuildContext } from "@repo/db";

export type ArelPermission = "GUILD_ADMIN" | "RAID_MANAGER" | "MEMBER";

const PERMISSION_RANK: Record<ArelPermission, number> = {
  GUILD_ADMIN: 2,
  RAID_MANAGER: 1,
  MEMBER: 0,
};

function higher(
  a: ArelPermission | null,
  b: ArelPermission | null,
): ArelPermission | null {
  if (!a) return b;
  if (!b) return a;
  return PERMISSION_RANK[a] >= PERMISSION_RANK[b] ? a : b;
}

export async function resolveArelRole(
  db: ReturnType<typeof withGuildContext>,
  guildId: string,
  userId: string,
): Promise<ArelPermission | null> {
  const [seat, member] = await Promise.all([
    db.guildSeat.findUnique({
      where: { guild_id_user_id: { guild_id: guildId, user_id: userId } },
      select: { seat_type: true },
    }),
    db.guildMember.findUnique({
      where: { guild_id_user_id: { guild_id: guildId, user_id: userId } },
      select: { discord_roles: true },
    }),
  ]);

  // Source 1: explicit seat grant (SeatType maps directly to ArelPermission)
  const seatPermission: ArelPermission | null = seat
    ? (seat.seat_type as ArelPermission)
    : null;

  // Source 2: Discord role → guild_role_mappings
  let discordPermission: ArelPermission | null = null;
  if (member && member.discord_roles.length > 0) {
    const mappings = await db.guildRoleMapping.findMany({
      where: {
        guild_id: guildId,
        discord_role_id: { in: member.discord_roles },
      },
      select: { arel_role: true },
    });
    for (const m of mappings) {
      discordPermission = higher(discordPermission, m.arel_role as ArelPermission);
    }
  }

  return higher(seatPermission, discordPermission);
}
