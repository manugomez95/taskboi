import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart' as impl;

/// Downloads a file with the given content and filename.
/// On web, triggers a browser download. On other platforms, returns false.
bool downloadFile(String content, String fileName) {
  return impl.downloadFile(content, fileName);
}
