import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:taskboi/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/link_parser.dart';

/// Plain text whose http(s) URLs are tappable and open externally.
class LinkifiedText extends StatefulWidget {
  const LinkifiedText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  State<LinkifiedText> createState() => _LinkifiedTextState();
}

class _LinkifiedTextState extends State<LinkifiedText> {
  final List<TapGestureRecognizer> _recognizers = [];

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  TapGestureRecognizer _recognizerFor(Uri uri) {
    final r = TapGestureRecognizer()..onTap = () => _open(uri);
    _recognizers.add(r);
    return r;
  }

  Future<void> _open(Uri uri) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final message = AppLocalizations.of(context)?.couldNotOpenLink;
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok && message != null) {
      messenger?.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final segments = parseLinks(widget.text);
    final base = widget.style ?? DefaultTextStyle.of(context).style;
    final linkStyle = base.copyWith(
      color: Theme.of(context).colorScheme.primary,
      decoration: base.decoration == TextDecoration.lineThrough
          ? TextDecoration.combine([
              TextDecoration.underline,
              TextDecoration.lineThrough,
            ])
          : TextDecoration.underline,
    );

    final spans = <InlineSpan>[
      for (final s in segments)
        if (s.isLink)
          TextSpan(
            text: s.text,
            style: linkStyle,
            mouseCursor: SystemMouseCursors.click,
            recognizer: _recognizerFor(s.uri!),
          )
        else
          TextSpan(text: s.text),
    ];

    return Text.rich(
      TextSpan(children: spans),
      style: widget.style,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}
