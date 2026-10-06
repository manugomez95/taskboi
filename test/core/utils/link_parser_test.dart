import 'package:flutter_test/flutter_test.dart';
import 'package:taskboi/core/utils/link_parser.dart';

List<String> links(String s) =>
    parseLinks(s).where((e) => e.isLink).map((e) => e.text).toList();

void main() {
  test('plain and empty text', () {
    expect(parseLinks(''), isEmpty);
    expect(parseLinks('hola mundo'), [const TextSegment('hola mundo')]);
  });

  test('single and multiple urls', () {
    expect(links('mira https://a.com/x y http://b.org'),
        ['https://a.com/x', 'http://b.org']);
    final s = parseLinks('ve a https://a.com ya');
    expect(s.map((e) => e.text).join(), 've a https://a.com ya');
    expect(s[1].uri, Uri.parse('https://a.com'));
  });

  test('www is upgraded to https', () {
    final s = parseLinks('www.example.com/p');
    expect(s.single.uri, Uri.parse('https://www.example.com/p'));
    expect(s.single.text, 'www.example.com/p');
  });

  test('trailing punctuation excluded', () {
    expect(links('ver https://a.com.'), ['https://a.com']);
    expect(links('(https://a.com), y https://b.com!'),
        ['https://a.com', 'https://b.com']);
    expect(parseLinks('ver https://a.com.').last.text, '.');
  });

  test('balanced parentheses kept', () {
    expect(links('https://en.wikipedia.org/wiki/Foo_(bar)'),
        ['https://en.wikipedia.org/wiki/Foo_(bar)']);
    expect(links('(https://en.wikipedia.org/wiki/Foo_(bar))'),
        ['https://en.wikipedia.org/wiki/Foo_(bar)']);
  });

  test('query and fragment preserved', () {
    expect(links('https://a.com/p?q=1&r=2#frag'),
        ['https://a.com/p?q=1&r=2#frag']);
  });

  test('non-http schemes and bare domains ignored', () {
    expect(
        links('javascript:alert(1) ftp://a.com file:///etc foo.com'), isEmpty);
  });

  test('unicode around url', () {
    expect(links('🔥https://a.com ñandú'), ['https://a.com']);
  });
}
