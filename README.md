# Taskboi

Taskboi is a cross-platform task manager built with Flutter and Supabase. It
supports offline use, real-time synchronization, recurring tasks, backups, and
optional Model Context Protocol (MCP) integrations.

Taskboi is licensed under the [Apache License 2.0](LICENSE). Release remains
subject to the dependency, SBOM, and attribution review documented in the
[release blockers](docs/RELEASE_BLOCKERS.md).

## Features

### Task management

- Unlimited projects with color customization
- Tasks with priorities, due dates, descriptions, recurring schedules, and subtasks
- Per-view sorting and drag-and-drop reordering

### Sync and appearance

- Real-time sync across devices via Supabase
- JSON backup export/import and offline support with automatic sync
- Ten color themes, light/dark/system modes, and responsive layouts

### Integrations and platforms

- MCP integration for AI-assisted task management
- Web at [taskboi.netlify.app](https://taskboi.netlify.app), macOS, iOS, and Android

## Architecture

| Area | Location | Responsibility |
| --- | --- | --- |
| Flutter client | `lib/` | UI, local Drift database, authentication, and sync |
| Supabase backend | `supabase/` | PostgreSQL schema/RLS, Edge Functions, storage, and realtime |
| Local MCP server | `taskboi-mcp/` | stdio MCP client using a user-created Taskboi API key |
| Remote MCP Worker | `taskboi-mcp/workers/` | OAuth-protected MCP service on Cloudflare Workers |

The client writes locally first and synchronizes authenticated user data with
Supabase. Backend row-level security is the authorization boundary; client-side
checks are not a substitute for it. The local MCP server holds the API key in
the MCP client's process environment. The remote Worker exchanges a Taskboi API
key for scoped, short-lived OAuth credentials and keeps upstream credentials in
server-side storage.

## Prerequisites

- A current stable Flutter SDK satisfying Dart `^3.6.2` and the resolved packages
- Node.js 18 or later and npm for MCP development
- Docker and the Supabase CLI for local backend work
- A platform toolchain supported by Flutter for the target device

Cloudflare, Netlify, app-store, and production Supabase access are not required
for normal development.

## Quick start

1. Clone the repository and install Flutter dependencies:

   ```sh
   flutter pub get
   ```

2. Create the ignored local configuration file:

   ```sh
   cp config/public.example.json public-config.local.json
   ```

3. Start a local Supabase stack, reset it to the committed migrations, and copy
   its public API URL and anonymous key into `public-config.local.json` as the
   exact `PUBLIC_SUPABASE_URL` and `PUBLIC_SUPABASE_ANON_KEY` Dart defines:

   ```sh
   supabase start
   supabase db reset
   ```

4. Run the client:

   ```sh
   flutter run --dart-define-from-file=public-config.local.json
   ```

For test commands and changes involving migrations, MCP, or the Worker, read
[CONTRIBUTING.md](CONTRIBUTING.md) first.

## Public configuration and secrets

`PUBLIC_SUPABASE_URL` and `PUBLIC_SUPABASE_ANON_KEY` are public client
configuration. They are embedded in released web/mobile clients and must never
be treated as an authorization control. Security depends on Supabase
authentication, RLS, storage policies, and server-side validation.

Never put service-role keys, direct database URLs, Taskboi API keys, OAuth
encryption keys, signing credentials, or provider access tokens in Dart defines,
MCP configuration committed to Git, `wrangler.toml`, issue reports, or logs.
Keep `public-config.local.json` limited to the two public settings above.

See [Public client configuration and secret handling](docs/configuration-and-secrets.md)
for local, server, CI, release scanning, and credential exposure guidance.

## MCP integrations

Taskboi supports the [Model Context Protocol](https://modelcontextprotocol.io/),
allowing AI assistants to manage tasks. Generate an API key in Taskboi under
**Settings > API Keys**, then follow the [local MCP server setup](taskboi-mcp/README.md)
for clients that can launch a local command and inject `TASKBOI_API_KEY`
privately. The [remote Worker](taskboi-mcp/workers/README.md) is an
operator-managed OAuth service. Do not deploy either service or use real
credentials while preparing a contribution.

Once connected, an assistant can list projects and tasks, create, update,
complete, or delete them, manage subtasks and recurring tasks, and show today or
upcoming views. The complete tool reference and MCP development commands are in
the [local MCP server documentation](taskboi-mcp/README.md).

## Project documentation

- [Contributing](CONTRIBUTING.md)
- [Security policy](SECURITY.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Changelog](CHANGELOG.md) and [release policy](docs/RELEASE_POLICY.md)
- [Database operations](supabase/README.md)
- [Third-party dependency review](docs/THIRD_PARTY_DEPENDENCIES.md)

## Support

Use [GitHub Issues](https://github.com/manugomez95/taskboi/issues) for
reproducible bugs and narrowly scoped feature proposals.
Search existing issues first and remove private data, tokens, account details,
and production identifiers from reports. Security vulnerabilities must follow
the private process in [SECURITY.md](SECURITY.md), not a public issue.

Maintainers provide support on a best-effort basis; no response time or release
schedule is guaranteed. The repository does not currently document a community
chat, support mailbox, or commercial support channel; Manuel must add those
links here if they are created.

> **Maintainer decision required:** choose a monitored support channel and
> decide whether to publish acknowledgement or resolution targets. Until then,
> GitHub Issues is the only documented support route and remains best-effort.

## For external users

The hosted web client is the simplest way to evaluate Taskboi. This repository
also documents local development, but it does not currently promise a supported
self-hosting distribution, hosted-service availability target, data-recovery
service, or compatibility window. Review the [privacy policy](web/privacy-policy.html).
Backup completeness has not been verified: only rely on the in-app JSON backup
for important data if you have confirmed that it includes the data you need and
have successfully tested restoring it with a compatible client.

Public releases, when approved, will be announced through the
[changelog](CHANGELOG.md) under the [release policy](docs/RELEASE_POLICY.md).
Repository source and the hosted service may change independently; a merged
commit is not a release.

## License status

Licensed under the [Apache License 2.0](LICENSE). The separate dependency,
SBOM, and attribution review remains a release requirement; see
[release blockers](docs/RELEASE_BLOCKERS.md).
