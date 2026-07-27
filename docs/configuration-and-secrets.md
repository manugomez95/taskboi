# Public client configuration and secret handling

## Flutter public configuration

The Flutter app accepts exactly two compile-time public client settings:

- `PUBLIC_SUPABASE_URL`
- `PUBLIC_SUPABASE_ANON_KEY`

The Supabase URL and anonymous key are public configuration. They are embedded in every client build by design and must never be described or managed as secrets. Security must come from Supabase Row Level Security and server-side authorization, not from hiding either value. Never put a service-role key, database password, signing key, webhook secret, or any other privileged credential in a Flutter setting.

For local development, copy `config/public.example.json` to the ignored `public-config.local.json`, replace only the public settings, and run:

```sh
flutter run --dart-define-from-file=public-config.local.json
```

The committed example contains inert placeholders and no credentials. `.env` is neither loaded nor shipped as an asset. The app fails at startup when either public setting is absent or the URL is malformed, without including values in the error.

For CI, store these two public settings as ordinary environment-specific build configuration and pass them explicitly:

```sh
flutter build appbundle --release \
  --dart-define=PUBLIC_SUPABASE_URL="$PUBLIC_SUPABASE_URL" \
  --dart-define=PUBLIC_SUPABASE_ANON_KEY="$PUBLIC_SUPABASE_ANON_KEY"
```

Although these values are public, avoid printing command traces or generated define files: build logs are durable and the same hygiene prevents a privileged value from being substituted accidentally. Server credentials belong in the hosting provider's encrypted secret store. Grant CI access only to the environment it releases, mask log output, and never pass privileged values through Flutter `--dart-define`, source files, build assets, or repository variables intended for public configuration.

## Required release gates

Install exactly Gitleaks `8.30.1`, verifying the checksum published with that release. The wrapper refuses other versions or a missing binary so local and CI results remain reproducible and fail closed.

Before any release, scan every ref and commit reachable in the repository:

```sh
./scripts/scan-secrets.sh history
```

After building and before upload or deployment, scan the exact release outputs. Archive traversal and common recursive encodings are enabled:

```sh
./scripts/scan-secrets.sh artifacts build/app/outputs/bundle/release/app-release.aab build/web
```

Pass every artifact being released (for example an AAB, APK, IPA, app bundle, or web output). A missing path, unavailable/wrong scanner version, scanner error, or finding blocks release. Scanner output is captured and discarded; the gate reports only pass/fail and never secret contents. CI should run both commands on a full clone (`fetch-depth: 0`) and must not upload artifacts unless both succeed.

## Exposure response

If a privileged credential is found, stop the release and do not paste the finding into tickets or chat. Revoke or rotate it at its issuer first, inspect access and audit logs, invalidate affected sessions/tokens where applicable, and deploy dependent server configuration safely. Remove the value from the current tree and, if it entered Git history, coordinate a history rewrite and fresh clones; deletion in a later commit is not revocation. Re-run both gates afterward. Treat release artifacts and logs containing the value as compromised and delete them according to the provider's retention controls.

Public Supabase URL or anonymous-key exposure does not itself require secret rotation because those values are public. Rotate/revoke only if the provider or project policy requires it, or if the value was actually a privileged credential mislabeled as public configuration.
