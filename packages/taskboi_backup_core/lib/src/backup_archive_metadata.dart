abstract final class BackupArchiveMetadata {
  static const currentFormatVersion = '1.0';
  static const supportedMajorVersions = {1};

  static bool supports(String version) {
    final match = RegExp(r'^(\d+)\.(\d+)$').firstMatch(version);
    return match != null &&
        supportedMajorVersions.contains(int.parse(match.group(1)!));
  }
}

final class UnsupportedBackupVersionException extends FormatException {
  UnsupportedBackupVersionException(this.version)
      : super('Unsupported backup version: $version');

  final String version;
}
