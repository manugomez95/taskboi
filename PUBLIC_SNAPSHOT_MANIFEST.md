# Public Snapshot Manifest

This is a local-only, source-only draft prepared from source commit
`4029bb5eae31368e14d4330b3350e4bccdb0328e`. It is not a publication approval,
legal approval, deployment approval, or a statement about any live service.

## Included

The tracked application, Flutter/Dart source, tests, platform project source,
Supabase schema/functions/tests, MCP/Worker source, documentation, policy
files, dependency manifests/locks, and public CI source are included, subject
to the exclusions and sanitizations below. `assets/icons/app_icon.jpg` is
included under the owner attestation recorded in `ASSET_PROVENANCE.md`.

## Excluded

- Internal material: `.hermes/agent-webhooks-spec.md`, `CLAUDE.md`.
- Operational material awaiting owner/legal evidence: `fastlane/Fastfile`,
  `scripts/deploy.sh`, `scripts/check-public-release-approval.py`.
- Fastlane configuration: `fastlane/Appfile` (omitted rather than publishing
  store identifiers; it would require a fully placeholder-only template if
  retained).
- Generated web database artifacts: `web/drift_worker.js`,
  `web/drift_worker.js.map`, `web/drift_worker.js.deps`, and
  `web/sqlite3.wasm`. The Dart source `web/drift_worker.dart` remains.
- Generated launcher derivatives: Android `ic_launcher*.png` and
  `ic_launcher_foreground.png` density outputs; all PNGs in iOS
  `AppIcon.appiconset`; all PNGs in macOS `AppIcon.appiconset`; `web/favicon.png`;
  and `web/icons/Icon-*.png` / `Icon-maskable-*.png`.
- Original iOS launch-image PNGs were not retained. The three required asset
  filenames are replaced with newly generated transparent 1x1 PNGs; see
  `ASSET_PROVENANCE.md`.

## Sanitized

- `config/public.example.json`: both original values replaced by inert,
  documented placeholders while retaining both keys. Operators must provide
  their own public-client URL and anon key in an untracked local config.
- `macos/Runner/Info.plist`: deployment-specific reverse OAuth scheme replaced
  with `com.example.taskboi.oauth`; the `taskboi` app custom scheme is retained.
- `supabase/config.toml`: project linkage replaced with
  `public-template-project-id`; alternatively remove the line and run
  `supabase link` against an operator-owned project.
- `taskboi-mcp/workers/wrangler.toml`: Worker name and canonical issuer use
  template placeholders. No Worker secret placeholder values were added;
  encryption/client secrets must be provisioned through the Worker secret
  store.

## Exact source paths omitted

The following 53 source paths are absent from this draft:

```text
.hermes/agent-webhooks-spec.md
CLAUDE.md
android/app/src/main/res/drawable-hdpi/ic_launcher_foreground.png
android/app/src/main/res/drawable-mdpi/ic_launcher_foreground.png
android/app/src/main/res/drawable-xhdpi/ic_launcher_foreground.png
android/app/src/main/res/drawable-xxhdpi/ic_launcher_foreground.png
android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png
android/app/src/main/res/mipmap-hdpi/ic_launcher.png
android/app/src/main/res/mipmap-mdpi/ic_launcher.png
android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
fastlane/Appfile
fastlane/Fastfile
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-50x50@1x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-57x57@1x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-57x57@2x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-72x72@1x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-72x72@2x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png
macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png
macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png
macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png
macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png
macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png
macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png
macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png
scripts/check-public-release-approval.py
scripts/deploy.sh
web/drift_worker.js
web/drift_worker.js.deps
web/drift_worker.js.map
web/favicon.png
web/icons/Icon-192.png
web/icons/Icon-512.png
web/icons/Icon-maskable-192.png
web/icons/Icon-maskable-512.png
web/sqlite3.wasm
```

## Regeneration and use

Generated launcher outputs must be regenerated by a downstream operator from
the retained source icon (or the operator's replacement asset) before platform
packaging. The neutral iOS launch images are structural placeholders only and
should be replaced with operator-owned artwork before release. Configure all
services, OAuth registrations, Supabase linkage, and deployment identities in
operator-owned environments.
