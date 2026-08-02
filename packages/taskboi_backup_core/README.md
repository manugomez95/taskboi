# taskboi_backup_core

Pure Dart definitions, JSON encoding/decoding, validation, and format-version
metadata for Taskboi backup archives. The package has no Flutter, database,
filesystem, authentication, or synchronization dependencies.

Both Taskboi OSS and Taskboi Internal should use this package as the canonical
archive contract. Each app remains responsible for mapping its own persistence
models to and from `BackupArchive`; the package intentionally contains no app
model mirrors or IO.

```dart
const codec = BackupArchiveCodec();
final json = codec.encode(archive);
final validatedArchive = codec.decode(json);
```

`decode` validates the JSON structure, ISO-8601 date-times, and supported
format major before returning an archive. The current writer format is exposed
as `BackupArchiveMetadata.currentFormatVersion`.

Run checks from this directory:

```sh
dart pub get
dart test
dart analyze
```
