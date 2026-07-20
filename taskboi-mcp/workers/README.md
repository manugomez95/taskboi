# Taskboi MCP Worker

Remote MCP server for Taskboi, deployed on Cloudflare Workers. It uses OAuth 2.0 Authorization Code with mandatory S256 PKCE. Access tokens are short-lived, opaque, scoped, revocable credentials; Taskboi API keys are never returned to MCP clients.

This component is licensed under the repository's
[Apache License 2.0](../../LICENSE). Deployment or release remains subject to
the separate dependency, SBOM, and attribution
[release requirement](../../docs/RELEASE_BLOCKERS.md).

## Deployment

### Prerequisites

1. [Cloudflare account](https://dash.cloudflare.com/sign-up)
2. [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/install-and-update/)

### Deploy

```bash
cd taskboi-mcp/workers

# Install dependencies
npm install

# Configure the required bindings as described below.

# Login to Cloudflare (first time only)
npx wrangler login

# Deploy
npm run deploy
```

After deployment, you'll get a URL like:
```
https://taskboi-mcp.<your-subdomain>.workers.dev
```

## Setup in Claude.ai

1. Go to **Claude.ai Settings > Connectors**
2. Click **"Add custom connector"**
3. Configure:
   - **Name**: `Taskboi`
   - **URL**: `https://taskboi-mcp.<your-subdomain>.workers.dev/mcp`
4. Complete the OAuth authorization screen. The API key entered there is validated and retained only in server-side Durable Object storage.

Do not put a Taskboi API key in an MCP URL or send it directly as a bearer token. The `/mcp` endpoint accepts only OAuth access tokens in the `Authorization: Bearer …` header.

## OAuth configuration

Two bindings are required. Set `OAUTH_ISSUER` to the Worker's canonical public HTTPS origin (for example, `https://mcp.taskboi.app`), with no trailing slash, path, query, fragment, or credentials. All discovery and OAuth endpoint URLs are derived from this value rather than the request Host header. Set `OAUTH_ENCRYPTION_KEY` as described below.

Before the first release of this OAuth-enabled Worker, configure `OAUTH_ENCRYPTION_KEY` as a secret. Wrangler 4.35 `versions upload` inherits secrets but does not offer `--keep-vars`; therefore every dashboard-managed plaintext variable (including `OAUTH_ISSUER`, and any optional OAuth variables in use) must first be copied exactly into the deployment's environment-specific Wrangler configuration. This is an operator prerequisite. The standard deploy path uploads an inactive candidate, inspects its JSON, requires every binding on every traffic-bearing version to be preserved (including exact plaintext values), validates the required OAuth binding types, and only then moves traffic with `versions deploy`.

The initial `OAUTH_STORE` Durable Object migration requires a one-time non-versioned deployment because Cloudflare cannot apply that migration with `versions upload`. The deploy script uses `wrangler deploy --keep-vars` only when the captured upload output contains the structured Cloudflare API error `[code: 10211]`; generic failures, prose that merely mentions 10211, and all other Cloudflare error codes remain fatal and never trigger direct activation. Before this fallback it validates the active binding metadata. Afterward it validates that the active version contains the `OAUTH_STORE` Durable Object, plaintext `OAUTH_ISSUER`, and secret `OAUTH_ENCRYPTION_KEY`, and that no prior binding was lost or changed except the one-time removal of obsolete `OAUTH_CLIENT_SECRET`. Binding values are never printed. Subsequent releases continue to use inactive candidate upload, validation, and `versions deploy`.

### One-time `OAUTH_CLIENT_SECRET` cleanup

`OAUTH_CLIENT_SECRET` is obsolete and compromised; current Worker code does not use it. The binding comparator contains one exact migration exception allowing only that binding to disappear. It does not allow removal of legacy `OAUTH_KV`, required `OAUTH_ENCRYPTION_KEY`, `OAUTH_STORE`, `OAUTH_ISSUER`, or any other binding, and it still rejects changes to every surviving binding.

Before the migration, use Cloudflare's binding metadata views to record the active version IDs and binding names/types without displaying or copying values. Confirm each traffic-bearing version has the expected bindings and that the configured candidate omits only `OAUTH_CLIENT_SECRET`. Upload the inactive candidate through the guarded release flow, then inspect its metadata before moving traffic: `OAUTH_CLIENT_SECRET` must be absent; `OAUTH_ENCRYPTION_KEY` must remain a secret, `OAUTH_STORE` a Durable Object namespace, and `OAUTH_ISSUER` plaintext; every other binding must be present and unchanged. After activation, repeat those metadata checks on the traffic-bearing version and smoke-test health, OAuth discovery, authorization, token exchange, and an authenticated MCP request. Do not print binding or secret values during any check.

If validation or smoke tests fail, immediately direct traffic back to the recorded prior code version and verify service recovery. Do not restore the compromised `OAUTH_CLIENT_SECRET`; the prior code does not require it. If Cloudflare cannot reactivate that version while keeping the obsolete binding absent, stop the rollout and build an equivalent rollback candidate that omits it. Validate the rollback candidate with the same metadata checks before moving traffic, then investigate before retrying the one-time migration.

`OAUTH_CLIENTS` is optional compatibility configuration for clients with a prior relationship. When present, each public client must have an ID, one or more exact redirect URIs, and the `mcp` scope:

```json
[
  {
    "client_id": "example-public-client",
    "redirect_uris": ["https://client.example/oauth/callback"],
    "scopes": ["mcp"]
  }
]
```

Add the optional JSON as a plaintext `OAUTH_CLIENTS` environment variable in the Cloudflare dashboard (Worker **Settings > Variables and Secrets**) or an environment-specific Wrangler configuration. A malformed or unsafe value fails closed, but an absent value is valid.

Client ID Metadata Documents are disabled by default. To trust known client publishers, add `OAUTH_CLIENT_METADATA_ALLOWED_ORIGINS` as a plaintext JSON array of exact canonical HTTPS origins, for example `["https://client-publisher.example"]`. Do not include paths or trailing slashes. Only client IDs whose normalized origin exactly matches this allowlist are fetched; an absent or empty allowlist rejects URL client IDs while static and dynamically registered clients continue to work. Invalid allowlist configuration makes the Worker fail closed.

Create a dedicated random 256-bit AES key, encode its 32 raw bytes as canonical standard base64 (44 characters, ending in `=`), and store it only as a Cloudflare Worker secret named `OAUTH_ENCRYPTION_KEY`. For example, generate and pipe a value directly to Wrangler without printing it:

```bash
openssl rand -base64 32 | npx wrangler secret put OAUTH_ENCRYPTION_KEY
```

Do not put this secret in `wrangler.toml`, `.dev.vars`, source control, logs, or documentation. A missing key, non-canonical base64, or a decoded length other than exactly 32 bytes makes every Worker route fail closed. Rotating the secret makes previously issued authorization codes and access tokens undecryptable, so revoke/expire them before rotation.

HTTPS redirect URIs are required, except loopback `http://localhost` and `http://127.0.0.1` URIs for native development clients. Do not add secrets or API keys to `wrangler.toml`. OAuth authorization codes expire after five minutes; access tokens expire after one hour and can be revoked at `/revoke`. Both authorization and token requests must contain exactly one `resource` parameter equal to the canonical `${OAUTH_ISSUER}/mcp` URL; codes and tokens remain bound to that audience.

## Client interoperability and security

Client registrations are resolved in this order: optional static `OAUTH_CLIENTS`, an allowlisted HTTPS Client ID Metadata Document when `client_id` is itself its URL, then a dynamically registered public client. Metadata documents must include `client_name`, identify themselves exactly, declare the authorization-code/public-client/S256 flow, and contain only exact safe redirect URIs. Client IDs require a non-root path and reject dot segments, queries, fragments, credentials, IP literals, localhost, and local/internal names. Fetches occur only for explicitly allowlisted origins, are bounded by time and size, do not follow redirects, and are cached briefly in separate Durable Object records.

`POST /register` implements Dynamic Client Registration for public authorization-code clients; `client_name` is optional and unknown client metadata members are accepted and ignored as required by RFC 7591 section 2. Registration does not require or return `code_challenge_methods_supported`, which is authorization-server metadata; S256 PKCE remains mandatory at `/authorize` and `/token`. It issues an opaque client ID and stores registration metadata separately from metadata-document cache entries. Registrations expire after 30 days and alarm cleanup frees capacity; at most 100 active DCR registrations are accepted globally using Durable Object transactional consistency. Capacity exhaustion is rejected safely and metadata cache entries do not count toward the cap. This implementation does not issue a client secret (and therefore omits `client_secret_expires_at`), registration access token, or support confidential authentication or registration management.

## Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Health check |
| `/authorize` | GET | OAuth authorization (S256 PKCE required) |
| `/.well-known/oauth-protected-resource/mcp` | GET | RFC 9728 protected-resource metadata |
| `/.well-known/oauth-authorization-server` | GET | RFC 8414 authorization-server metadata |
| `/register` | POST | Public-client dynamic registration |
| `/token` | POST | Authorization-code exchange |
| `/revoke` | POST | Access-token revocation |
| `/mcp` | POST | MCP endpoint (Streamable HTTP) |

## Local Development

```bash
npm run dev

# Test health check
curl http://localhost:8787/
```

## Custom Domain (Optional)

To use `mcp.taskboi.app`:

1. Add domain to Cloudflare
2. Edit `wrangler.toml`:
   ```toml
   routes = [
     { pattern = "mcp.taskboi.app", custom_domain = true }
   ]
   ```
3. Run `npm run deploy`

## Available Tools

- **Projects**: list_projects, get_inbox, get_project, create_project, update_project, delete_project
- **Tasks**: list_tasks, get_task, get_today_tasks, get_upcoming_tasks, get_subtasks, create_task, update_task, complete_task, uncomplete_task, delete_task
