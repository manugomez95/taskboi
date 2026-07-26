# Changelog

All notable changes to Taskboi will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning will follow the policy in [docs/RELEASE_POLICY.md](docs/RELEASE_POLICY.md)
after the first public release and resolution of all release blockers.

## [Unreleased]

### Added

- Release gates for value-suppressed full-history and artifact secret scans,
  plus explicit public-only Flutter configuration validation.
- External contribution, security, conduct, ownership, issue, pull request, and
  release governance documentation.
- Explicit supported-version and coordinated vulnerability disclosure policy,
  with unresolved private intake and response targets recorded for maintainers.
- Structured bug and feature intake, pull request checks, review ownership, and
  external-user support and release expectations.
- Apache License 2.0 project licensing and a regression check for the exact
  license text and publishable package metadata.

### Changed

- Removed fixed agent assignment profiles, webhook dispatch, and assignee-only
  task query surfaces from the portable OSS core.
- Reworked the README for external setup, architecture, configuration security,
  MCP boundaries, and support.
- Replaced the pending-license release blocker with the selected Apache-2.0
  license while retaining dependency, SBOM, and attribution review as a
  separate release requirement.

## Historical versions

Versions before this changelog was introduced were not reconstructed. Git tags
and commit history remain the source for that history; future releases must add
a dated section and comparison links as described by the release policy.
