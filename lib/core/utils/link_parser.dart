/// A piece of text, optionally carrying a launchable http(s) [uri].
class TextSegment {
  const TextSegment(this.text, [this.uri]);

  final String text;
  final Uri? uri;

  bool get isLink => uri != null;

  @override
  bool operator ==(Object other) =>
      other is TextSegment && other.text == text && other.uri == uri;

  @override
  int get hashCode => Object.hash(text, uri);

  @override
  String toString() => 'TextSegment($text, $uri)';
}

final RegExp _candidate = RegExp(
  r'(?:https?://|www\.)[^\s<>]+',
  caseSensitive: false,
);

const String _trailing = '.,;:!?\'"';

/// Splits [input] into plain and link segments. Only http/https links are
/// produced; `www.` links are upgraded to https.
List<TextSegment> parseLinks(String input) {
  final segments = <TextSegment>[];
  var cursor = 0;

  void addPlain(String s) {
    if (s.isEmpty) return;
    if (segments.isNotEmpty && !segments.last.isLink) {
      segments[segments.length - 1] = TextSegment(segments.last.text + s);
    } else {
      segments.add(TextSegment(s));
    }
  }

  for (final m in _candidate.allMatches(input)) {
    var url = m.group(0)!;
    url = _trimTrailing(url);
    final uri = _toUri(url);
    if (uri == null) continue;
    addPlain(input.substring(cursor, m.start));
    segments.add(TextSegment(url, uri));
    cursor = m.start + url.length;
    // Anything trimmed off stays in the plain text via the next addPlain.
  }
  addPlain(input.substring(cursor));
  return segments;
}

String _trimTrailing(String url) {
  var end = url.length;
  while (end > 0) {
    final c = url[end - 1];
    if (_trailing.contains(c)) {
      end--;
    } else if (c == ')' || c == ']') {
      final open = c == ')' ? '(' : '[';
      final body = url.substring(0, end);
      final opens = open.allMatches(body).length;
      final closes = c.allMatches(body).length;
      if (closes > opens) {
        end--;
      } else {
        break;
      }
    } else {
      break;
    }
  }
  return url.substring(0, end);
}

Uri? _toUri(String url) {
  final withScheme =
      url.toLowerCase().startsWith('www.') ? 'https://$url' : url;
  final uri = Uri.tryParse(withScheme);
  if (uri == null) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  if (uri.host.isEmpty || !uri.host.contains('.') && uri.host != 'localhost') {
    return null;
  }
  return uri;
}
