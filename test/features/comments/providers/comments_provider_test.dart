import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskboi/core/database/database.dart';
import 'package:taskboi/core/sync/sync_operation.dart';
import 'package:taskboi/core/sync/sync_service.dart';
import 'package:taskboi/features/comments/providers/comments_provider.dart';

class _MockSyncService extends Mock implements SyncService {}

class _MockRef extends Mock implements Ref<Object?> {}

void main() {
  late AppDatabase db;
  late _MockSyncService syncService;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-anon-key',
    );
    registerFallbackValue(SyncEntityType.comment);
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    syncService = _MockSyncService();
  });

  tearDown(() async {
    await db.close();
  });

  test('queue create failure returns notCreated after local upsert', () async {
    when(() => syncService.queueCreate(any(), any(), any()))
        .thenThrow(Exception('queue unavailable'));
    final notifier = CommentsNotifier(
      db,
      syncService,
      'user-id',
      _MockRef(),
    );

    final result = await notifier.createComment(
      taskId: 'task-id',
      content: 'Keep this draft',
    );

    expect(result.status, CommentCreationStatus.notCreated);
    expect(result.comment, isNull);
    expect(await db.select(db.comments).get(), isEmpty);
    verify(() => syncService.queueCreate(
          SyncEntityType.comment,
          any(),
          any(),
        )).called(1);
  });
}
