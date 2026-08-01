import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taskboi/features/comments/data/models/comment.dart';
import 'package:taskboi/features/comments/presentation/widgets/comment_list.dart';
import 'package:taskboi/features/comments/providers/comments_provider.dart';
import 'package:taskboi/l10n/generated/app_localizations.dart';

void main() {
  Widget buildField({
    TargetPlatform platform = TargetPlatform.android,
    CommentImagePicker? imagePicker,
    CommentCreator? commentCreator,
    CommentAttachmentRetrier? attachmentRetrier,
  }) {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AddCommentField(
            taskId: 'task-id',
            platform: platform,
            imagePicker: imagePicker,
            commentCreator: commentCreator,
            attachmentRetrier: attachmentRetrier,
          ),
        ),
      ),
    );
  }

  test('desktop platforms only support gallery comment images', () {
    for (final platform in [
      TargetPlatform.macOS,
      TargetPlatform.linux,
      TargetPlatform.windows,
    ]) {
      expect(commentImageSources(platform), [ImageSource.gallery]);
    }
    expect(
      commentImageSources(TargetPlatform.android),
      [ImageSource.camera, ImageSource.gallery],
    );
    expect(
      commentImageSources(TargetPlatform.iOS),
      [ImageSource.camera, ImageSource.gallery],
    );
  });

  testWidgets('macOS attachment menu omits camera and offers gallery',
      (tester) async {
    await tester.pumpWidget(buildField(platform: TargetPlatform.macOS));

    await tester.tap(find.byIcon(Icons.image_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Camera'), findsNothing);
    expect(find.text('Gallery'), findsOneWidget);
  });

  testWidgets('picker errors use a safe message', (tester) async {
    await tester.pumpWidget(buildField(
      platform: TargetPlatform.macOS,
      imagePicker: (_) async => throw StateError('picker unavailable'),
    ));

    await tester.tap(find.byIcon(Icons.image_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gallery'));
    await tester.pumpAndSettle();

    expect(
        find.textContaining("Couldn't open the image picker"), findsOneWidget);
    expect(find.textContaining('picker unavailable'), findsNothing);
  });

  testWidgets('failed create preserves draft text and reports the error',
      (tester) async {
    await tester.pumpWidget(buildField(
      commentCreator: ({
        required String taskId,
        required String content,
        required List<File> imageFiles,
      }) async =>
          const CommentCreationResult.notCreated(),
    ));

    await tester.enterText(find.byType(TextField), 'Keep this draft');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('Keep this draft'), findsOneWidget);
    expect(find.textContaining("Couldn't add the comment"), findsOneWidget);
  });

  testWidgets('unexpected create errors use a safe message and preserve draft',
      (tester) async {
    await tester.pumpWidget(buildField(
      commentCreator: ({
        required String taskId,
        required String content,
        required List<File> imageFiles,
      }) async =>
          throw Exception('Image upload failed'),
    ));

    await tester.enterText(find.byType(TextField), 'Keep upload draft');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('Keep upload draft'), findsOneWidget);
    expect(find.textContaining("Couldn't add the comment"), findsOneWidget);
    expect(find.textContaining('Image upload failed'), findsNothing);
  });

  testWidgets(
      'partial attachment failure retries existing comment without creating duplicate',
      (tester) async {
    var createCalls = 0;
    var retryCalls = 0;
    String? retriedCommentId;
    await tester.pumpWidget(buildField(
      imagePicker: (_) async => XFile('/tmp/pending-comment-image.jpg'),
      commentCreator: ({
        required String taskId,
        required String content,
        required List<File> imageFiles,
      }) async {
        createCalls++;
        return CommentCreationResult.attachmentsPending(Comment(
          id: 'existing-comment-id',
          taskId: taskId,
          userId: 'user-id',
          content: content,
        ));
      },
      attachmentRetrier: ({
        required String commentId,
        required List<File> imageFiles,
      }) async {
        retryCalls++;
        retriedCommentId = commentId;
        expect(imageFiles, hasLength(1));
        return true;
      },
    ));

    await tester.tap(find.byIcon(Icons.image_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gallery'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Created once');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(createCalls, 1);
    expect(find.text('Created once'), findsNothing);
    expect(find.textContaining('comment was added'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(createCalls, 1);
    expect(retryCalls, 1);
    expect(retriedCommentId, 'existing-comment-id');
  });

  testWidgets('successful create clears the draft', (tester) async {
    await tester.pumpWidget(buildField(
      commentCreator: ({
        required String taskId,
        required String content,
        required List<File> imageFiles,
      }) async =>
          CommentCreationResult.created(Comment(
        id: 'comment-id',
        taskId: taskId,
        userId: 'user-id',
        content: content,
      )),
    ));

    await tester.enterText(find.byType(TextField), 'Send this draft');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('Send this draft'), findsNothing);
  });
}
