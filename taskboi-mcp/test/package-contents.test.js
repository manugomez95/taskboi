import assert from "node:assert/strict";
import {
  cpSync,
  mkdirSync,
  mkdtempSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { delimiter, dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";
import test from "node:test";

const packageRoot = dirname(dirname(fileURLToPath(import.meta.url)));
const npm = process.platform === "win32" ? "npm.cmd" : "npm";

test("npm package excludes stale legacy tool build outputs", (t) => {
  const fixture = mkdtempSync(join(packageRoot, ".package-test-"));
  t.after(() => rmSync(fixture, { force: true, recursive: true }));

  for (const entry of ["bin", "scripts", "src", "package.json", "tsconfig.json"]) {
    cpSync(join(packageRoot, entry), join(fixture, entry), { recursive: true });
  }

  const staleTools = join(fixture, "dist", "tools");
  mkdirSync(staleTools, { recursive: true });
  for (const name of ["projects", "tasks"]) {
    writeFileSync(join(staleTools, `${name}.js`), "export const stale = true;\n");
    writeFileSync(join(staleTools, `${name}.d.ts`), "export declare const stale: true;\n");
    writeFileSync(join(staleTools, `${name}.js.map`), "{}\n");
    writeFileSync(join(staleTools, `${name}.d.ts.map`), "{}\n");
  }

  const env = {
    ...process.env,
    PATH: `${join(packageRoot, "node_modules", ".bin")}${delimiter}${process.env.PATH ?? ""}`,
  };
  execFileSync(npm, ["run", "build"], { cwd: fixture, env, stdio: "pipe" });
  const pack = JSON.parse(execFileSync(
    npm,
    ["pack", "--dry-run", "--json"],
    { cwd: fixture, env, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] },
  ));
  const files = pack[0].files.map(({ path }) => path);

  for (const legacyPrefix of [
    "dist/tools/projects.",
    "dist/tools/tasks.",
  ]) {
    assert.ok(
      !files.some((path) => path.startsWith(legacyPrefix)),
      `tarball contains stale ${legacyPrefix} output`,
    );
  }
});
