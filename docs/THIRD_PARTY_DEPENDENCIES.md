# Third-party Dependency Review

This is an engineering inventory for release review, not legal advice and not a
substitute for the license texts shipped by each dependency.

## Sources audited

- `pubspec.yaml` and the resolved `pubspec.lock` for Flutter/Dart packages;
- `deno.json` and `deno.lock` for Supabase Edge Functions;
- CocoaPods, Android/Gradle, Flutter SDK, bundled web artifacts, and repository
  assets as additional distribution surfaces requiring final review.

The MCP integration is a separate project and is outside this repository's
dependency, packaging, and release scope.

## Required pre-release review

- Generate a complete bill of materials from the exact release locks and
  toolchains, retaining package versions, license texts, notices, and sources.
- Review direct and transitive Dart packages from their resolved package license
  files; `pubspec.lock` does not carry SPDX license fields.
- Inventory native CocoaPods, Swift packages, Gradle/Maven artifacts, Flutter
  engine components, generated Drift files, icons, fonts, and bundled assets.
- Produce any required NOTICE, attribution, license-text, or source-offer
  materials for the exact distribution channel.

`scripts/generate-compliance-inventory.py` produces deterministic JSON,
Markdown, SPDX 2.3 evidence, and checksums for the complete committed
public-core source tree. Its automated dependency package and SPDX relationship
coverage is deliberately narrower: it parses only `pubspec.lock`. It records
committed `deno.lock`, CocoaPods `Podfile.lock`, and Swift
`Package.resolved` inputs with **no automated package coverage** and an explicit
final-review requirement. Those Deno and native packages must be inventoried
from the exact locks and toolchains before any artifact or package publication;
they are not represented in the generated dependency list or SPDX package
relationships.

Unknown Dart dependency licenses and unverified asset provenance remain
`NOASSERTION`; the evidence is not a complete dependency BOM, an approval, or a
legal compatibility finding.

The release-candidate workflow builds only the core Flutter web candidate. It
does not install, build, pack, publish, or attest an MCP npm package. The
workflow records candidate members, verifies expected tracked web assets,
validates SPDX evidence, checksums and secret-scans every candidate file, and
attests before upload. Uploading this internal candidate is not a public
release; the approved public distribution remains source only.

The project license is Apache-2.0. Completion of dependency, SBOM, attribution,
and asset review remains tracked in
[RELEASE_BLOCKERS.md](RELEASE_BLOCKERS.md).
