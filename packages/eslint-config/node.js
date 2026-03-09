import { config as baseConfig } from "./base.js";
import globals from "globals";

/**
 * ESLint configuration for Node.js apps and packages.
 *
 * @type {import("eslint").Linter.Config[]}
 */
export const nodeConfig = [
  ...baseConfig,
  {
    languageOptions: {
      globals: {
        ...globals.node,
      },
    },
  },
];
