import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../data/models/comment.dart';
import '../../providers/comments_provider.dart';

class CommentList extends ConsumerWidget {
  final String taskId;

  const CommentList({
    super.key,
    required this.taskId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsAsync = ref.watch(commentsStreamProvider(taskId));

    return commentsAsync.when(
      data: (comments) {
        if (comments.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: comments
              .map((comment) => CommentTile(
                    comment: comment,
                    taskId: taskId,
                  ))
              .toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Full-screen image viewer with pinch-to-zoom support.
class FullScreenImageViewer extends StatelessWidget {
  final String commentId;
  final List<String> images;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.commentId,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final pageController = PageController(initialPage: initialIndex);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: pageController,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return InteractiveDualView(
            commentId: commentId,
            imageUrl: images[index],
          );
        },
      ),
    );
  }
}

/// Interactive image display with zoom and pan.
class InteractiveDualView extends ConsumerStatefulWidget {
  final String commentId;
  final String imageUrl;

  const InteractiveDualView({
    super.key,
    required this.commentId,
    required this.imageUrl,
  });

  @override
  ConsumerState<InteractiveDualView> createState() =>
      _InteractiveDualViewState();
}

class _InteractiveDualViewState extends ConsumerState<InteractiveDualView> {
  final TransformationController _controller = TransformationController();
  TapDownDetails? _doubleTapDetails;
  late Future<String> _url;

  @override
  void initState() {
    super.initState();
    _url = ref
        .read(commentsNotifierProvider.notifier)
        .resolveImageUrl(widget.commentId, widget.imageUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_controller.value == Matrix4.identity()) {
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      _controller.value = Matrix4.identity()
        ..translateByDouble(-position.dx * 2, -position.dy * 2, 0, 1)
        ..scaleByDouble(3.0, 3.0, 3.0, 1);
    } else {
      _controller.value = Matrix4.identity();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: _handleDoubleTapDown,
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: 1.0,
        maxScale: 4.0,
        child: Center(
          child: FutureBuilder<String>(
            future: _url,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return Image.network(
                snapshot.data!,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image_outlined,
                        size: 48, color: Colors.white54),
                    SizedBox(height: 8),
                    Text('Failed to load image',
                        style: TextStyle(color: Colors.white54)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Thumbnail widget for a comment image.
class CommentImageThumbnail extends ConsumerStatefulWidget {
  final String commentId;
  final String imageUrl;

  const CommentImageThumbnail({
    super.key,
    required this.commentId,
    required this.imageUrl,
  });

  @override
  ConsumerState<CommentImageThumbnail> createState() =>
      _CommentImageThumbnailState();
}

class _CommentImageThumbnailState extends ConsumerState<CommentImageThumbnail> {
  late Future<String> _url;

  @override
  void initState() {
    super.initState();
    _url = ref
        .read(commentsNotifierProvider.notifier)
        .resolveImageUrl(widget.commentId, widget.imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: FutureBuilder<String>(
        future: _url,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(
              width: 80,
              height: 80,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          return Image.network(
            snapshot.data!,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 80,
                height: 80,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              width: 80,
              height: 80,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.broken_image_outlined, size: 20),
            ),
          );
        },
      ),
    );
  }
}

/// Horizontal strip of image thumbnails for a comment.
class CommentImagesRow extends StatelessWidget {
  final String commentId;
  final List<String> images;

  const CommentImagesRow({
    super.key,
    required this.commentId,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FullScreenImageViewer(
                    commentId: commentId,
                    images: images,
                    initialIndex: index,
                  ),
                ),
              );
            },
            child: CommentImageThumbnail(
              commentId: commentId,
              imageUrl: images[index],
            ),
          );
        },
      ),
    );
  }
}

class CommentTile extends ConsumerStatefulWidget {
  final Comment comment;
  final String taskId;

  const CommentTile({
    super.key,
    required this.comment,
    required this.taskId,
  });

  @override
  ConsumerState<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends ConsumerState<CommentTile> {
  bool _isEditing = false;
  late TextEditingController _editController;
  List<File> _editImageFiles = [];

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.comment.content);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date, AppLocalizations l10n) {
    if (date == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final commentDate = DateTime(date.year, date.month, date.day);

    if (commentDate == today) {
      return l10n.todayYesterday(DateFormat.jm().format(date));
    } else if (commentDate == yesterday) {
      return l10n.yesterdayTime(DateFormat.jm().format(date));
    } else if (date.year == now.year) {
      return DateFormat('MMM d, h:mm a').format(date);
    }
    return DateFormat('MMM d, y h:mm a').format(date);
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _editController.text = widget.comment.content;
      _editImageFiles = [];
    });
  }

  Future<void> _saveEdit() async {
    final newContent = _editController.text.trim();
    if (newContent.isEmpty || newContent == widget.comment.content) {
      setState(() => _isEditing = false);
      return;
    }

    // Upload new images if any were picked during edit
    List<String> imageUrls = List.from(widget.comment.images);
    var newImageIds = <String>[];
    if (_editImageFiles.isNotEmpty) {
      // Optimistically keep existing + new images; upload happens in provider
      final notifier = ref.read(commentsNotifierProvider.notifier);
      // Upload new images and merge with existing
      newImageIds =
          await notifier.uploadImages(_editImageFiles, widget.comment.id);
      imageUrls = [...widget.comment.images, ...newImageIds];
    }

    await ref.read(commentsNotifierProvider.notifier).updateComment(
          id: widget.comment.id,
          content: newContent,
          images: imageUrls,
          unattachedImageIds: newImageIds,
        );
    setState(() {
      _isEditing = false;
      _editImageFiles = [];
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _editController.text = widget.comment.content;
      _editImageFiles = [];
    });
  }

  Future<void> _deleteComment() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(commentsNotifierProvider.notifier);

    notifier.markPendingDeletion(widget.comment.id);

    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger
        .showSnackBar(
          SnackBar(
            content: Text(l10n.commentDeleted),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: l10n.undo,
              onPressed: () {
                notifier.clearPendingDeletion(widget.comment.id);
              },
            ),
          ),
        )
        .closed
        .then((reason) {
      if (reason != SnackBarClosedReason.action) {
        notifier.deleteComment(widget.comment.id);
      }
      notifier.clearPendingDeletion(widget.comment.id);
    });
  }

  void _showOptions() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(l10n.edit),
              onTap: () {
                Navigator.pop(context);
                _startEditing();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title:
                  Text(l10n.delete, style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteComment();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.2),
                child: Icon(
                  Icons.person,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(widget.comment.createdAt, l10n),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (!_isEditing)
                InkWell(
                  onTap: _showOptions,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.more_horiz,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isEditing)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _editController,
                  autofocus: true,
                  maxLines: null,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: l10n.editComment,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
                if (widget.comment.images.isNotEmpty ||
                    _editImageFiles.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _EditImagesPreview(
                    commentId: widget.comment.id,
                    existingImages: widget.comment.images,
                    newFiles: _editImageFiles,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _cancelEdit,
                      child: Text(l10n.cancel),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _saveEdit,
                      child: Text(l10n.save),
                    ),
                  ],
                ),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.comment.content,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (widget.comment.images.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    CommentImagesRow(
                      commentId: widget.comment.id,
                      images: widget.comment.images,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Preview of existing + newly-picked images during edit mode.
class _EditImagesPreview extends StatelessWidget {
  final String commentId;
  final List<String> existingImages;
  final List<File> newFiles;

  const _EditImagesPreview({
    required this.commentId,
    required this.existingImages,
    required this.newFiles,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Existing images (from server)
          ...existingImages.map((url) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CommentImageThumbnail(
                  commentId: commentId,
                  imageUrl: url,
                ),
              )),
          // Newly picked images (local files)
          ...newFiles.map((file) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    file,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class AddCommentField extends ConsumerStatefulWidget {
  final String taskId;

  const AddCommentField({
    super.key,
    required this.taskId,
  });

  @override
  ConsumerState<AddCommentField> createState() => _AddCommentFieldState();
}

class _AddCommentFieldState extends ConsumerState<AddCommentField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _imagePicker = ImagePicker();
  bool _isSubmitting = false;
  List<File> _pickedImages = [];

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _pickedImages.add(File(image.path));
        });
      }
    } catch (_) {
      // User cancelled or permission denied
    }
  }

  void _showImageSourcePicker() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, size: 20),
              title: Text(l10n.camera),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, size: 20),
              title: Text(l10n.gallery),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _removePickedImage(int index) {
    setState(() {
      _pickedImages.removeAt(index);
    });
  }

  Future<void> _submitComment() async {
    final content = _controller.text.trim();
    if ((content.isEmpty && _pickedImages.isEmpty) || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    final imagesToSend = List<File>.from(_pickedImages);

    await ref.read(commentsNotifierProvider.notifier).createComment(
          taskId: widget.taskId,
          content: content,
          imageFiles: imagesToSend,
        );

    _controller.clear();
    _focusNode.unfocus();
    setState(() {
      _isSubmitting = false;
      _pickedImages = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Picked images preview
        if (_pickedImages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _pickedImages.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _pickedImages[index],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => _removePickedImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Attach image button
            IconButton(
              onPressed: _isSubmitting ? null : _showImageSourcePicker,
              icon: Icon(
                Icons.image_outlined,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: null,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submitComment(),
                decoration: InputDecoration(
                  hintText: l10n.addComment,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _isSubmitting ? null : _submitComment,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      Icons.send,
                      color: theme.colorScheme.primary,
                    ),
            ),
          ],
        ),
      ],
    );
  }
}
