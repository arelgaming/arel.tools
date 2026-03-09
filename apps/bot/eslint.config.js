import { nodeConfig } from "@repo/eslint-config/node";
import { dbBoundaryConfig } from "@repo/eslint-config/boundaries";

/** @type {import("eslint").Linter.Config[]} */
export default [...nodeConfig, ...dbBoundaryConfig];
