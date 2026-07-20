# Asset Provenance

## Owner-authorized retained asset

`assets/icons/app_icon.jpg` is retained under the supplied owner attestation:
it is owner-authored and licensed Apache-2.0. This attestation is limited to
that named source asset; it is not a broader legal approval or a claim about
other assets or deployments.

## Excluded derived assets

Generated Android, iOS, macOS, and web launcher derivatives are excluded from
this source-only draft. A downstream operator must regenerate those outputs
from `assets/icons/app_icon.jpg` or from replacement artwork they are entitled
to use. No provenance is asserted here for the excluded derived files.

## iOS launch images

The original `LaunchImage.png`, `LaunchImage@2x.png`, and
`LaunchImage@3x.png` were excluded. Their filenames are required by
`ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json`, so each has
been newly generated as a transparent 1x1 PNG solely to keep the asset catalog
structurally complete. These placeholders are not product artwork and must be
replaced with operator-owned launch artwork before any release.
