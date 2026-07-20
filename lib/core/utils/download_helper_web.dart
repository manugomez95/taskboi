import 'dart:js_interop';

@JS('Blob')
extension type _Blob._(JSObject _) implements JSObject {
  external factory _Blob(JSArray<JSString> parts, _BlobPropertyBag options);
}

extension type _BlobPropertyBag._(JSObject _) implements JSObject {
  external factory _BlobPropertyBag({String type});
}

@JS('URL.createObjectURL')
external String _createObjectUrl(_Blob blob);

@JS('URL.revokeObjectURL')
external void _revokeObjectUrl(String url);

@JS('document.createElement')
external _AnchorElement _createElement(String tagName);

extension type _AnchorElement._(JSObject _) implements JSObject {
  external set href(String value);
  external set download(String value);
  external void click();
}

/// Web implementation that triggers a browser download.
bool downloadFile(String content, String fileName) {
  final blob =
      _Blob([content.toJS].toJS, _BlobPropertyBag(type: 'application/json'));
  final url = _createObjectUrl(blob);
  _createElement('a')
    ..href = url
    ..download = fileName
    ..click();
  _revokeObjectUrl(url);
  return true;
}
