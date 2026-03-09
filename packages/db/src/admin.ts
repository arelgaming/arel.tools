import { PrismaClient } from "@prisma/client";

const globalForAdmin = globalThis as unknown as {
  adminPrisma: PrismaClient | undefined;
};

export const adminPrisma =
  globalForAdmin.adminPrisma ??
  new PrismaClient({
    datasources: { db: { url: process.env["ADMIN_DATABASE_URL"] } },
  });

if (process.env["NODE_ENV"] !== "production") {
  globalForAdmin.adminPrisma = adminPrisma;
}
