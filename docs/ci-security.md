# CI and release security

Taskboi's required checks use immutable dependency locks and commit-pinned
toolchains/actions. CI has read-only repository access, does not receive
deployment credentials, and does not deploy. The `Release candidate` workflow
only packages artifacts from `main`; it requires approval through the protected
`release` environment and produces SHA-256 checksums, an SPDX SBOM, GitHub
artifact provenance, and an SBOM attestation. It never publishes a release.

## Repository settings

Configure rulesets or branch protection for both `main` and `develop`:

- require pull requests with at least one approving review and dismissal of
  stale approvals;
- require CODEOWNER review when a `CODEOWNERS` file is introduced;
- require conversation resolution and branches to be current before merge;
- require the checks `Flutter tests and analyze`, `MCP build and typecheck`,
  `Worker tests and typecheck`, `Migrations and Supabase functions`,
  `Secret scan`, and `Workflow regression checks`;
- block force pushes, branch deletion, and bypasses (including administrators);
- require signed commits where the organization can support them;
- disable merge commits if linear history is required by the release process.

Private-repository branch protection and ruleset controls are available only on
GitHub plans that support them. Listing these checks is guidance for supported
plans, not a guarantee that they are enforced in this repository.

Create a GitHub environment named `release`, restrict it to `main`, add required
reviewers, prevent self-review, and do not store deployment secrets in it. Keep
GitHub Actions restricted to selected actions. Every action in this repository
is referenced by a full commit SHA; Dependabot proposes updates, but branch
protection should be configured to require human review and all required checks
before those updates can merge, where those controls are available.

The MAN-212 scanner is `scripts/scan-secrets.sh`. CI invokes it through
`scripts/ci/secret-scan.sh`, which downloads the pinned Gitleaks release and
verifies its SHA-256 checksum before scanning full Git history. Scanner output
is suppressed by the MAN-212 gate so findings cannot expose matched values.
Release artifacts are scanned before attestation or upload. Both adapters fail
closed for missing tools, missing artifacts, findings, and scanner errors.
The small historical allowlist uses exact Gitleaks fingerprints for only eight
dependency-lockfile false positives. The retired static OAuth credential must
never be allowlisted. Do not replace these fingerprints with path, rule, commit,
or pattern-wide exceptions.

## Dependency-review scope

This private internal repository does not run GitHub dependency review because
the organization has deliberately not enabled the paid GitHub Advanced Security
capability it requires for private repositories. This is a scope boundary, not
a passing dependency-review security result. Dependency review is required when
changes are promoted to the public OSS repository, `manugomez95/taskboi`; that
public-repository policy is managed separately from this internal CI workflow.

## Reproducibility rules

- Dart uses committed `pubspec.lock` with `--enforce-lockfile`.
- Both Node projects use committed `package-lock.json` files with `npm ci`.
- Deno remote modules use exact versions and integrity data in `deno.lock`.
- Flutter is checked out by commit, including in Netlify builds.
- Flutter code generation runs in CI and `scripts/ci/check-generated-output.sh`
  rejects tracked drift or unexpected untracked files before analyze and tests.
- Action tags in comments are informational; the full SHA is authoritative.

Reviewers should reject dependency changes that modify a manifest without its
lockfile, action updates that are not full SHAs, or release changes that add
credentials, publishing, or deployment to these workflows.
