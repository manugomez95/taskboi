# Taskboi

Taskboi is an open-source, cross-platform task manager built with Flutter. Run it locally, adapt it to your workflow, or deploy your own instance. It includes projects, tasks, recurring schedules, offline use, backups, and optional MCP integrations.

[Apache-2.0 licensed](LICENSE) · [Report a bug or propose a focused change](https://github.com/manugomez95/taskboi/issues)

> **Managed hosting:** Taskboi Cloud is planned and coming soon. This repository is the open-source project; cloning or self-hosting it does not create or depend on a managed account.

## Choose your path

| You want to… | Start here |
| --- | --- |
| Try or contribute to the app locally | [Run locally](#run-locally) |
| Get free multi-device sync without operating servers | [Use your own free Supabase project](#use-your-own-free-supabase-project) |
| Operate your own synchronized instance | [Self-hosting](#self-hosting) |
| Work without an account or server | Use the local database and JSON backup/import features; multi-device sync needs a backend |
| Wait for managed hosting | Taskboi Cloud — coming soon |

## What is included

- Projects, tasks, subtasks, priorities, due dates, notes, sorting, and recurring schedules
- Offline-first client storage with a local Drift database
- Optional synchronization across devices
- JSON backup export and import
- Light, dark, and system themes across Flutter-supported platforms
- Optional Model Context Protocol (MCP) integrations

## Use your own free Supabase project

For many individuals, the easiest path to private, multi-device Taskboi sync is a **free project in their own [Supabase](https://supabase.com/pricing) account**. It provides the hosted database, authentication, realtime, and storage that Taskboi uses—without operating Docker, a server, or waiting for a managed Taskboi offering.

You remain the owner and administrator of that Supabase project: create it, apply Taskboi's migrations and functions using [the database runbook](supabase/README.md), then set its project URL and anonymous key in `public-config.local.json`. Your Taskboi clients can use that configuration across supported platforms.

This is your own Supabase deployment, not a Taskboi-managed account; your data lives in the project you created. Supabase's free-plan limits and inactivity policy can change, so review its current pricing and operational limits before relying on it for important data.

## Self-hosting

Taskboi is open source, but the app is **not database-agnostic today**. A full self-hosted setup uses a self-managed [Supabase](https://supabase.com) stack: PostgreSQL, authentication, realtime, storage, row-level security, and the included migrations/functions. Supabase Cloud is not required.

This repository currently documents a developer-oriented self-hosting path. A one-command Docker Compose distribution is planned but is not available yet. Until then, use Docker plus the Supabase CLI to run the local stack.

### Requirements

- Flutter SDK compatible with Dart `^3.6.2`
- Docker and the Supabase CLI
- Node.js 18+ and npm when working on MCP components
- The platform toolchain for your chosen Flutter target

### Run locally

1. Clone the repository and fetch Flutter packages:

   ```sh
   git clone https://github.com/manugomez95/taskboi.git
   cd taskboi
   flutter pub get
   ```

2. Create your untracked public client configuration:

   ```sh
   cp config/public.example.json public-config.local.json
   ```

3. Start your local Supabase services and apply Taskboi's committed schema:

   ```sh
   supabase start
   supabase db reset
   ```

4. Copy the local Supabase API URL and anonymous key shown by the CLI into `public-config.local.json` as `PUBLIC_SUPABASE_URL` and `PUBLIC_SUPABASE_ANON_KEY`, then run the client:

   ```sh
   flutter run --dart-define-from-file=public-config.local.json
   ```

`PUBLIC_SUPABASE_URL` and `PUBLIC_SUPABASE_ANON_KEY` are public client configuration, not secrets. Do not put a service-role key, direct database URL, signing key, OAuth secret, or provider token in this file.

For database operations, migrations, and production-oriented safeguards, read [the Supabase runbook](supabase/README.md). For development and tests, read [CONTRIBUTING.md](CONTRIBUTING.md).

## Architecture

| Component | Purpose |
| --- | --- |
| Flutter client (`lib/`) | UI, local database, authentication, and sync |
| Supabase (`supabase/`) | PostgreSQL schema, RLS, auth, realtime, storage, and functions |
| Local MCP server (`taskboi-mcp/`) | Optional MCP integration for locally configured clients |
| Remote MCP worker (`taskboi-mcp/workers/`) | Optional operator-managed OAuth MCP service |

The app writes locally first, then synchronizes authenticated data with your Supabase instance. Row-level security and server-side validation are the authorization boundary; client-side checks are not a replacement for them.

## Managed hosting

Taskboi Cloud is planned and not available yet. Until it launches, use your own Supabase project for the easiest cloud-backed setup, or self-host the full stack.

- You do not need a managed Taskboi account to run the source code.
- Self-hosted operators own their infrastructure, security configuration, backups, and upgrades.
- A future managed offering will have its own terms and lifecycle, separate from public releases.

## MCP integrations

MCP is optional. The local server and remote OAuth worker are for operators who want AI clients to interact with their Taskboi data. See [the local MCP documentation](taskboi-mcp/README.md) and [the remote worker documentation](taskboi-mcp/workers/README.md) before deploying or connecting an MCP client.

## Documentation

- [Contributing](CONTRIBUTING.md)
- [Database operations](supabase/README.md)
- [Configuration and secret handling](docs/configuration-and-secrets.md)
- [Security policy](SECURITY.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Changelog](CHANGELOG.md) and [release policy](docs/RELEASE_POLICY.md)

## Support and limitations

Use [GitHub Issues](https://github.com/manugomez95/taskboi/issues) for reproducible bugs and narrowly scoped proposals. Please remove credentials, private data, and production identifiers. Report security vulnerabilities through the private process in [SECURITY.md](SECURITY.md), not in a public issue.

This is source code, not a managed backup or availability service. Test restore procedures before relying on backups for important data. Public releases and the hosted service have separate lifecycles.
