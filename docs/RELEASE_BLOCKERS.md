# Release Blockers

## Project license selection

**Status: resolved 2026-07-18.**

Taskboi uses the Apache License 2.0 and includes its official text in
[`LICENSE`](../LICENSE).

## Dependency, SBOM, asset, and attribution review

**Status: blocking artifact and package publication.**

Before distributing anything beyond the approved public-core source, maintainers
must review the exact Flutter, Dart, Deno, native, and asset inputs described in
[THIRD_PARTY_DEPENDENCIES.md](THIRD_PARTY_DEPENDENCIES.md), produce required
notices and license materials, and confirm the candidate metadata matches that
review.

The deterministic compliance inventory and release-candidate comparison are
engineering evidence only. Unknown license and provenance findings remain
explicit, and no artifact publication approval is inferred. Automated package
and SPDX dependency coverage is limited to `pubspec.lock`; the recorded Deno,
CocoaPods, and Swift lockfiles retain a mandatory final-review gate because
their packages have no automated coverage.

The MCP integration is maintained and reviewed separately in its canonical
repository. This public core neither packages it nor grants approval for an MCP
release.
