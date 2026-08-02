import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('backup service is an adapter over taskboi_backup_core', () {
    final service = File(
      'lib/features/backup/data/services/backup_service.dart',
    ).readAsStringSync();

    expect(service,
        contains('package:taskboi_backup_core/taskboi_backup_core.dart'));
    expect(service, contains('_codec.encode('));
    expect(service, contains('_codec.decode('));
    expect(service, isNot(contains("import 'dart:convert'")));
  });

  test('the app does not maintain a second archive model', () {
    expect(
      File('lib/features/backup/data/models/backup_format.dart').existsSync(),
      isFalse,
    );
  });
}
