# Release Blockers

## Project license selection

**Status: resolved 2026-07-18.**

Manuel selected the Apache License 2.0. The repository contains the official
license text in [`LICENSE`](../LICENSE), and publishable package metadata uses
the SPDX identifier `Apache-2.0`.

No root `NOTICE` is currently required because no factual project notice has
been identified. Add one only when there is an actual project or third-party
notice to distribute.

## Dependency, SBOM, and attribution review

**Status: blocking release and package publication.**

License selection does not resolve dependency compatibility or distribution
obligations. Before release, maintainers must:

1. review the direct and transitive dependency licenses summarized in
   [THIRD_PARTY_DEPENDENCIES.md](THIRD_PARTY_DEPENDENCIES.md), including the
   LGPL-bearing optional platform packages in the Worker development tree;
2. determine obligations for source, binary, app-store, npm, web, and hosted
   service distribution with appropriate legal advice if needed;
3. produce the SBOM and required notices, attributions, license texts, and any
   source-offer materials for each release channel; and
4. confirm that release artifacts and metadata accurately reflect the completed
   review.

The release-candidate artifact now includes deterministic JSON and Markdown
inventories, an SPDX committed-input SBOM, and verified checksums generated for
the exact source revision from committed dependency inputs and tracked assets.
The workflow refuses to continue when either expected candidate archive is
absent, records actual archive members, compares tracked web assets by hash, and
applies repository-owned SPDX 2.3 structural and semantic checks before
attestation. This does not represent external SPDX certification.
Unknown license/provenance findings and native resolution gaps remain explicit
review inputs. This is review evidence only: the review template remains `NOT
APPROVED`, and the existing release and package-publication blocker remains in
force.

This document records an operational blocker and does not provide a legal
compatibility conclusion.
