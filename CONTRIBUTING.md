# Contributing to Taskboi

Thank you for helping improve Taskboi. By participating, you agree to follow the
[Code of Conduct](CODE_OF_CONDUCT.md).

## Before starting

Search existing issues and keep changes focused. For security problems, use the
private process in [SECURITY.md](SECURITY.md). Contributions are made under the
project's [Apache License 2.0](LICENSE). The dependency, SBOM, and attribution
review remains a [release requirement](docs/RELEASE_BLOCKERS.md).

Never include credentials, production data, private URLs, account identifiers,
or copied user content in code, tests, fixtures, screenshots, commits, issues,
or pull requests. Use clearly fake values.

## Local setup

Install the prerequisites in the [README](README.md), then:

```sh
flutter pub get
cp config/public.example.json public-config.local.json
supabase start
supabase db reset
flutter run --dart-define-from-file=public-config.local.json
```

Set exactly `PUBLIC_SUPABASE_URL` and `PUBLIC_SUPABASE_ANON_KEY` in the ignored
`public-config.local.json`. They are public client configuration, but a
service-role key and direct database URL are secrets and must not be placed
there. Do not link the CLI to a shared or production project for routine
contribution work.

## Checks

The canonical local technical-health command runs the same source-only
validation surfaces as pull-request CI:

```sh
scripts/ci/technical-health.sh
```

It requires the repository-approved Flutter revision
`924134a44c189315be2148659913dda1671cbe99`, the revision installed by CI, and
Deno `2.9.3`. The command uses an inert temporary public configuration for
Flutter tests; it does not use `public-config.local.json`.

For a focused check, pass one or more explicitly named components. The component
names are `flutter-dependencies`, `flutter-generated`, `flutter-format`,
`flutter-analyze`, `flutter-test`, `backend-migrations`, `backend-check`,
`backend-test`, `secret-scan`, and `workflows`. Pull-request CI invokes these
same components in separate steps and jobs so failures remain actionable.

The repository does not configure a reliable unused-Dart-dependency detector,
so technical health does not claim to detect unused dependencies. Dependency
changes still require the release review described above.

Do not run deployment, Fastlane release lanes, or production Supabase commands
as part of contribution validation.

Integration tests may need a disposable local Supabase stack and an emulator or
device:

```sh
flutter test integration_test --dart-define-from-file=public-config.local.json
```

## Code and documentation style

Use `dart format` and keep analyzer warnings at zero. Follow the feature-based
layout and Riverpod conventions in [CLAUDE.md](CLAUDE.md). UI changes must also
follow [STYLE_GUIDE.md](STYLE_GUIDE.md), including its shared spacing, radius,
color, and icon values. Preserve the optimistic-update and animation ordering
rules documented in `CLAUDE.md`.

Keep Markdown headings descriptive, wrap prose consistently, and use relative
links for repository files. When Freezed, JSON serialization, Riverpod, or Drift
annotations change, regenerate the corresponding tracked files with the
repository-compatible `build_runner` command and review the generated diff; do
not hand-edit generated `*.g.dart` or `*.freezed.dart` files.

## Database migrations

Create forward-only, numbered SQL migrations in `supabase/migrations/`. Never
edit a migration already applied to a shared environment. Test from a clean
local database with `supabase db reset`, then run the SQL tests if pgTAP is
available in the local stack.

Migrations 017 and 018 have explicit production preconditions and a guarded,
one-way finalization. Contributors must read [supabase/README.md](supabase/README.md)
but must not run production pre-steps, `supabase db push`, direct-database
scripts, Edge Function deployment, or privacy finalization. Those are release
operator actions requiring backups, compatible clients, and authorized secret
access.

## MCP integration

The MCP integration is a separate project. Propose server, Worker, packaging,
and MCP-specific documentation changes in the canonical
[Taskboi MCP repository](https://github.com/manugomez95/taskboi-mcp) and
configure the integration according to that repository. Do not vendor or add a
local MCP package to this public core repository.

## Pull requests

- Use a conventional commit such as `docs: add release governance`.
- Explain behavior and security impact, list exact checks, and note migrations,
  generated files, dependency changes, and operator actions.
- Update `CHANGELOG.md` under **Unreleased** for user- or operator-visible work.
- Keep generated Dart files in sync when model annotations change.
- Do not combine deployment, credential rotation, or repository-setting changes
  with a code contribution.

Maintainers may squash or rebase contributions. Approval does not authorize a
deployment or release; follow [the release policy](docs/RELEASE_POLICY.md).
