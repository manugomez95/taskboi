# Security Policy

## Reporting a vulnerability

First check the repository's **Security** tab. If GitHub displays **Report a
vulnerability**, you may use that option to send the report privately. This
repository does not currently verify that private vulnerability reporting is
enabled, so do not rely on a direct advisory URL being available.

If GitHub does not display that option, use the repository's **Security contact
request** issue form to ask the maintainers to provide a private reporting
channel. Because that request is public, include no vulnerability details,
reproduction steps, affected versions, credentials, personal data, production
identifiers, or links or attachments that reveal them. You may instead contact
a maintainer through a previously verified private channel. Do not send details
to a guessed email address.

> **Maintainer decision required:** Manuel must enable and periodically test
> GitHub private vulnerability reporting and may replace this note with a
> monitored security email address. No private security mailbox is currently
> documented by the repository.

Do not open a public issue, discussion, or pull request containing exploit
details, credentials, personal data, or production identifiers. If GitHub does
not show the private reporting option, follow the detail-free fallback above.

Include, when safe:

- the affected component and revision or version;
- reproduction steps or a minimal proof of concept;
- the expected and observed impact;
- any suggested mitigation; and
- whether the issue is already public or actively exploited.

Do not access data that is not yours, degrade services, use social engineering,
or retain sensitive data while researching a report.

## Response targets

Maintainers will acknowledge reports and coordinate validation, remediation,
and disclosure on a best-effort basis. No acknowledgement, status-update, or
remediation deadline is currently promised.

> **Maintainer decision required:** Manuel must choose realistic targets for
> acknowledgement, initial assessment, status updates, and remediation before
> publishing an SLA. Until then, reporters should use the same private report
> thread to request status.

## Coordinated disclosure and embargo

Reporters and maintainers should keep vulnerability details, reproductions, and
fixes private until a coordinated disclosure date is agreed or the maintainers
publish an advisory. The embargo should last only as long as reasonably needed
to validate the report, prepare and distribute a fix, and give affected users
time to upgrade. Maintainers will share information before disclosure only with
people needed to remediate the issue and will ask those people to preserve the
embargo.

If there is evidence of active exploitation, imminent user harm, or an already
public disclosure, either party should raise that fact in the private thread so
the timeline can be shortened. If the parties cannot agree on timing, they
should document their proposed dates and risks in the private thread before
either party discloses. A GitHub Security Advisory may be used to coordinate a
fix, request a CVE, credit reporters, and publish the final advisory.

## Supported versions

| Version | Supported |
| --- | --- |
| Current default branch | Yes, before the first public release |
| Tagged or packaged releases | No public release support window is defined yet |
| Older commits and forks | No |

After releases begin, maintainers must replace this table with concrete version
ranges and end-of-support dates. Versions not explicitly listed as supported
should be assumed unsupported. Fork maintainers are responsible for their own
security updates.

## Credentials accidentally exposed

Revoke or rotate the credential with its provider immediately. Removing it from
Git history is not sufficient. Then use the private reporting process above if
the exposure affects other users or deployed infrastructure.
