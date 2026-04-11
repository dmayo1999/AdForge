import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    pool: "forks",
    fileParallelism: true,
    environment: "node",
    globals: false,
    include: ["lib/**/*.test.ts", "api/**/*.test.ts"],
    coverage: {
      provider: "v8",
      reporter: ["text", "html"],
      include: ["lib/**/*.ts", "api/**/*.ts"],
      exclude: ["**/*.test.ts", "**/node_modules/**"],
    },
  },
});
