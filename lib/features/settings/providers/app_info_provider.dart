import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Provider that fetches app package info (version, build number, etc.)
final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return await PackageInfo.fromPlatform();
});

/// Convenience provider for just the app version string (e.g., "1.0.0")
final appVersionProvider = Provider<String>((ref) {
  final packageInfo = ref.watch(packageInfoProvider);
  return packageInfo.valueOrNull?.version ?? '';
});

/// Convenience provider for the full version with build number (e.g., "1.0.0 (19)")
final appFullVersionProvider = Provider<String>((ref) {
  final packageInfo = ref.watch(packageInfoProvider);
  final info = packageInfo.valueOrNull;
  if (info == null) return '';
  return '${info.version} (${info.buildNumber})';
});
