import { describe, expect, it } from "vitest";
import { assertBindingsPreserved, isDurableObjectMigrationUploadError } from "../../../scripts/worker-binding-comparator.mjs";
// @ts-expect-error Vite supplies text imports through its raw query loader.
import deployScript from "../../../scripts/deploy.sh?raw";

describe("Durable Object migration upload fallback detection", () => {
  it("matches only a structured Cloudflare API error code 10211", () => {
    expect(isDurableObjectMigrationUploadError("A request to the Cloudflare API failed. [code: 10211]")).toBe(true);
    expect(isDurableObjectMigrationUploadError("Upload failed: network connection closed")).toBe(false);
    expect(isDurableObjectMigrationUploadError("The documentation mentions Cloudflare error 10211")).toBe(false);
    expect(isDurableObjectMigrationUploadError("A request to the Cloudflare API failed. [code: 10000]")).toBe(false);
  });
});

describe("deployment command output handling", () => {
  it("captures sensitive Wrangler output in private temporary files", () => {
    expect(deployScript).toContain('chmod 600 "$deployment_json" "$upload_output" "$direct_deploy_output"');
    expect(deployScript).toContain('versions upload --config "$WORKER_CONFIG" --name "$WORKER_NAME" --message "Validated release candidate" >"$upload_output" 2>&1');
    expect(deployScript).toContain('deploy --keep-vars --config "$WORKER_CONFIG" --name "$WORKER_NAME" >"$direct_deploy_output" 2>&1');
    expect(deployScript).not.toMatch(/versions upload[^\n]*\|\s*tee/);
  });

  it("keeps code-10211 detection against the captured upload output", () => {
    expect(deployScript).toContain('isDurableObjectMigrationUploadError(fs.readFileSync(outputFile, "utf8"))');
  });
});

describe("deployment candidate binding comparison", () => {
  it("deeply compares complete non-secret bindings independent of key order", () => {
    const active = [{ name: "DB", type: "durable_object_namespace", namespace: "x", metadata: { b: [2, 1], a: true } }];
    expect(() => assertBindingsPreserved(active, [{ metadata: { a: true, b: [2, 1] }, namespace: "x", type: "durable_object_namespace", name: "DB" }, { name: "NEW", type: "plain_text", text: "ok" }])).not.toThrow();
    expect(() => assertBindingsPreserved(active, [{ ...active[0], metadata: { b: [1, 2], a: true } }])).toThrow("Candidate changed binding DB");
    expect(() => assertBindingsPreserved(active, [])).toThrow("Candidate is missing binding DB");
  });

  it("compares secret type and all non-value metadata without comparing values", () => {
    const active = [{ name: "KEY", type: "secret_text", text: "unavailable", version: "v1", metadata: { source: "dashboard" } }];
    expect(() => assertBindingsPreserved(active, [{ name: "KEY", type: "secret_text", value: "also-unavailable", version: "v1", metadata: { source: "dashboard" } }])).not.toThrow();
    expect(() => assertBindingsPreserved(active, [{ name: "KEY", type: "secret_text", version: "v2", metadata: { source: "dashboard" } }])).toThrow("Candidate changed binding KEY");
    expect(() => assertBindingsPreserved(active, [{ name: "KEY", type: "plain_text", text: "secret" }])).toThrow("Candidate changed binding KEY");
  });

  it("permits only the one-time OAUTH_CLIENT_SECRET removal", () => {
    const active = [
      { name: "OAUTH_KV", type: "kv_namespace", namespace_id: "legacy" },
      { name: "OAUTH_CLIENT_SECRET", type: "secret_text", version: "v1" },
      { name: "OAUTH_ENCRYPTION_KEY", type: "secret_text", version: "key-v1" },
      { name: "OAUTH_STORE", type: "durable_object_namespace", class_name: "OAuthStore" },
      { name: "OAUTH_ISSUER", type: "plain_text", text: "https://worker.example" },
      { name: "TASKS", type: "kv_namespace", namespace_id: "tasks" },
    ];
    const candidate = active.filter((binding) => binding.name !== "OAUTH_CLIENT_SECRET");

    expect(() => assertBindingsPreserved(active, candidate)).not.toThrow();

    for (const name of ["OAUTH_ENCRYPTION_KEY", "OAUTH_STORE", "OAUTH_ISSUER", "OAUTH_KV", "TASKS"]) {
      expect(() => assertBindingsPreserved(active, active.filter((binding) => binding.name !== name))).toThrow(`Candidate is missing binding ${name}`);
    }
  });

  it("rejects changes to every surviving binding during the one-time removal", () => {
    const active = [
      { name: "OAUTH_CLIENT_SECRET", type: "secret_text", version: "v1" },
      { name: "OAUTH_ENCRYPTION_KEY", type: "secret_text", version: "key-v1" },
      { name: "OAUTH_STORE", type: "durable_object_namespace", class_name: "OAuthStore" },
      { name: "OAUTH_ISSUER", type: "plain_text", text: "https://worker.example" },
      { name: "TASKS", type: "kv_namespace", namespace_id: "tasks" },
    ];
    const withoutObsoleteSecret = active.filter((binding) => binding.name !== "OAUTH_CLIENT_SECRET");

    for (const binding of withoutObsoleteSecret) {
      const candidate = withoutObsoleteSecret.map((item) => item.name === binding.name ? { ...item, migration_test_change: true } : item);
      expect(() => assertBindingsPreserved(active, candidate)).toThrow(`Candidate changed binding ${binding.name}`);
    }
  });
});
