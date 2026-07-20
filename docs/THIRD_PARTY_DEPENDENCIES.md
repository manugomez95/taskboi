# Third-party Dependency Review

This is an engineering inventory for release review, not legal advice and not a
substitute for the license texts shipped by each dependency.

Audit snapshot: 2026-07-19, using the committed lockfiles and production npm
audit scope (`npm audit --omit=dev`).

## Sources audited

- `pubspec.yaml` and the resolved `pubspec.lock` for Flutter/Dart packages;
- `taskboi-mcp/package.json` and `package-lock.json`;
- `taskboi-mcp/workers/package.json` and `package-lock.json`; and
- CocoaPods, Android/Gradle, Flutter SDK, bundled web artifacts, and repository
  assets as additional distribution surfaces requiring final review.

The npm lockfiles contain SPDX metadata for every locked package at the time of
this audit. The local MCP tree reports MIT, BSD-2-Clause, BSD-3-Clause, ISC, and
Apache-2.0 packages. The Worker development tree additionally reports 0BSD,
CC0-1.0, dual MIT/Apache-2.0 choices, and LGPL-3.0-or-later expressions.

The LGPL expressions occur in optional platform packages beneath the transitive
`sharp` toolchain (`@img/sharp-libvips-*`, `@img/sharp-wasm32`, and Windows
`@img/sharp-*` packages). They appear in development/build dependencies, but
their inclusion in distributed artifacts and corresponding obligations must be
verified rather than assumed. Lockfile declarations alone are not a
compatibility determination.

The production npm audit scope reports zero findings in the local MCP tree and
zero findings in the Worker tree. The committed Worker lockfile separately
contains `LGPL-3.0-or-later` metadata in its development tree. Maintainers must
assess distribution and reachable production impact and test reviewed upgrades
before release; do not apply automated major-version fixes without
compatibility review.

## Required pre-release review

- Generate a complete bill of materials from the exact release lockfiles and
  toolchains, retaining package versions, license texts, notices, and source
  locations.
- Review direct and transitive Dart packages from their resolved package license
  files; `pubspec.lock` does not carry SPDX license fields.
- Inventory native CocoaPods, Swift packages, Gradle/Maven artifacts, Flutter
  engine components, `web/sqlite3.wasm`, generated Drift Worker files, icons,
  fonts, and other bundled assets.
- Confirm whether development-only and platform-optional packages enter any
  published npm tarball, Worker bundle, application binary, source archive, or
  container.
- Produce required NOTICE/attribution/source-offer materials for every release
  channel and automate the inventory so dependency updates cannot bypass it.

`scripts/generate-compliance-inventory.py` now produces deterministic JSON,
Markdown, an SPDX 2.3 committed-input SBOM, and a checksum manifest from the
committed source revision. Missing lockfile
license metadata and unverified tracked-asset provenance are recorded as
`NOASSERTION` and summarized as explicit review findings; that inventory is not
an approval or compatibility finding. The candidate workflow creates and
immediately verifies a sorted checksum manifest covering every candidate file
except the manifest itself. It also fails closed unless both expected archives
exist, records their normalized member paths, sizes, and hashes, and hash-checks
copied tracked web/pubspec assets against the inventory. The Flutter-transformed
`index.html` is presence-checked and its resulting hash is recorded. Generated compiled web files
are recorded but do not have a one-to-one source-asset identity; npm runtime
dependencies are inventoried but are not embedded in the npm package tarball.
Both the SPDX committed-input document and the artifact-scanner SPDX document
are checked by the tested, repository-owned
`scripts/validate-spdx.py` structural and referential-semantic validator. This
is reproducible local validation, not a claim of external SPDX certification.

For the current `release-candidate.yml`, the only payloads are the Flutter web
archive and the `taskboi-mcp` npm tarball. The Worker project is not installed,
built, or packed, and native applications are not built. Consequently, the
LGPL expressions in optional Worker development packages are classified as
`not-entering` those current payloads. This classification must be repeated for
any changed workflow or distribution channel and is not a license decision.
The missing committed `ios/Podfile.lock` and Gradle dependency locks remain
reproducibility gaps for native candidates; declarations are inventoried, but
do not substitute for resolved graphs. Do not treat the macOS CocoaPods lock or
SwiftPM pins as iOS resolution evidence.

The project license is Apache-2.0. Completion of this separate dependency,
SBOM, and attribution review is tracked in
[RELEASE_BLOCKERS.md](RELEASE_BLOCKERS.md); no dependency compatibility
conclusion is asserted here.
