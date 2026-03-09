/**
 * ESLint boundary config — blocks @repo/db imports.
 * Include this in every eslint.config.js EXCEPT apps/api.
 *
 * @type {import("eslint").Linter.Config[]}
 */
export const dbBoundaryConfig = [
  {
    rules: {
      "no-restricted-imports": [
        "error",
        {
          patterns: [
            {
              group: ["@repo/db", "@repo/db/*"],
              message:
                "Only apps/api can import @repo/db. Route data access through @repo/trpc.",
            },
          ],
        },
      ],
    },
  },
];

/**
 * ESLint boundary config — blocks adminPrisma imports outside admin handlers.
 * Apply this to non-admin router files inside apps/api.
 *
 * @type {import("eslint").Linter.Config[]}
 */
export const adminDbBoundaryConfig = [
  {
    rules: {
      "no-restricted-imports": [
        "error",
        {
          patterns: [
            {
              group: ["*/admin.js", "**/db/src/admin*"],
              message:
                "adminPrisma is only for internalAdminProcedure handlers.",
            },
          ],
        },
      ],
    },
  },
];
