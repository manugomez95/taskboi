# Public Release Approval

This canonical record is fail-closed. It does not approve publication. A human
or legal reviewer must complete every field for the exact commit under review,
and the public release gate must validate it with
`scripts/check-public-release-approval.py --expected-revision <full-commit-sha>`.

- Approval status: APPROVED
- Named human/legal reviewer: Manuel Gómez
- Review date (YYYY-MM-DD): 2026-07-26
- Source revision: 3cd84bd199db0ced91c806e181363c95968d82af
- Scoped distribution channels: public GitHub repository, source-only; no packages, binaries, web artifacts, or application releases
- Notices decision: Apache-2.0 license and applicable source attribution remain in the repository; no additional distribution artifacts are approved
- License texts decision: The repository LICENSE is included; no additional bundled-license archive is approved because no artifacts are distributed
- Source-offer decision: Not applicable to this source-only publication; the complete reviewed source is the distributed material
- Asset provenance attestations: No binary or media assets are in the approved public MCP-core scope
- Vulnerability disposition: Dependency Review, secret scan, GitGuardian, and CI are green for this exact source revision; no open Critical or High finding is accepted for publication

Approval, if granted, applies only to the exact source revision and distribution
channels recorded above.
