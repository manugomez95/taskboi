import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('production sources stay pure Dart and dependency-free', () {
    final sources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final source in sources) {
      final contents = source.readAsStringSync();
      expect(contents, isNot(contains("import 'package:flutter/")),
          reason: source.path);
      expect(contents, isNot(contains("import 'package:drift/")),
          reason: source.path);
      expect(contents, isNot(contains("import 'dart:io'")),
          reason: source.path);
    }
  });
}
