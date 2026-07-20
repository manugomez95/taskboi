# Release Policy

Taskboi uses maintainer-led releases. A merged change is not automatically a
release, deployment, or authorization to publish a package.

## Versioning and changelog

After the first public release, use Semantic Versioning for public interfaces:

- **major** for incompatible API, data-format, or operator changes;
- **minor** for backward-compatible functionality; and
- **patch** for backward-compatible fixes.

The Flutter build number may increase independently for app-store delivery.
Before merging user- or operator-visible work, update `CHANGELOG.md` under
**Unreleased**. At release time, move entries into `## [X.Y.Z] - YYYY-MM-DD`, add
comparison links, and keep an empty **Unreleased** section.

No release cadence, maintenance window, or end-of-support interval is promised.
Supported versions are listed only in [SECURITY.md](../SECURITY.md).

## Release gates

A maintainer must verify all of the following before publishing:

1. [Release blockers](RELEASE_BLOCKERS.md) are closed. Apache-2.0 selection is
   resolved, but dependency compatibility, SBOM, and attribution review remains
   required.
2. The intended commit is reviewed, the worktree is clean, and the version and
   changelog agree across release artifacts.
3. Flutter formatting, analysis, unit/widget tests, applicable integration and
   Supabase tests, MCP build, and Worker test/typecheck/dry-run build pass.
4. Security reports affecting the release are resolved or explicitly assessed;
   generated artifacts and dependency changes have been reviewed.
5. Database backups, rollback/forward-fix plans, client compatibility, and every
   migration precondition in [the database runbook](../supabase/README.md) are
   confirmed by an authorized operator.
6. Worker bindings and secrets are configured and validated by an authorized
   operator following [the Worker runbook](../taskboi-mcp/workers/README.md).
7. Published artifacts, release notes, tags, and package metadata make the same
   support and license claims.

> **Maintainer decision required — dependency licensing:** before the first
> public release, Manuel must record approval of the dependency, SBOM, notice,
> attribution, and distribution review in
> [RELEASE_BLOCKERS.md](RELEASE_BLOCKERS.md). Apache-2.0 is already selected for
> Taskboi itself; this placeholder does not make a legal compatibility claim.

## Release procedure

Prepare releases in a reviewed pull request. A maintainer chooses the version,
freezes the changelog, runs the gates above, and creates an annotated Git tag
for the exact reviewed commit. GitHub releases and other artifacts should be
built from that tag with release notes copied from the changelog.

Deployment is a separate, authorized operation. `scripts/deploy.sh` can push,
bump versions, deploy a Worker, and invoke store release automation; it must not
be used for ordinary validation or by untrusted contributions. Production
migrations and guarded finalization steps must be recorded without recording
secrets.

The release owner must record the version, tag, reviewed commit, completed gate
evidence, published artifacts, and any authorized operator actions in the
release pull request or release record. A second maintainer review is preferred
when available but is not claimed as a control while the project has only one
documented code owner.

If a release fails, stop promotion, preserve diagnostic evidence without secret
values, and use a reviewed forward fix or documented platform rollback. Never
rewrite a published tag or silently replace an artifact; publish a new version.

## Security releases

Use a private GitHub Security Advisory when appropriate. Limit advance details,
test the fix privately, coordinate disclosure, and publish patched versions and
clear upgrade guidance together. Follow [SECURITY.md](../SECURITY.md).

## Deprecation and support changes

Announce planned breaking removals and support-window changes in **Unreleased**
before release whenever security or urgent compatibility work permits. Release
notes must identify affected users, migration steps, and the last supported
version. Maintainers may accelerate a change when continued support would
create material security or data-integrity risk, with that reason documented.
