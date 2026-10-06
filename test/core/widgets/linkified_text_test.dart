import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskboi/core/widgets/linkified_text.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakeLauncher extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  final launched = <String>[];
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return true;
  }
}

void main() {
  late _FakeLauncher launcher;
  setUp(() {
    launcher = _FakeLauncher();
    UrlLauncherPlatform.instance = launcher;
  });

  Widget host(Widget child, {VoidCallback? onOuterTap}) => MaterialApp(
        home: Scaffold(
          body: GestureDetector(
            onTap: onOuterTap,
            behavior: HitTestBehavior.opaque,
            child: Center(child: child),
          ),
        ),
      );

  testWidgets('tapping link launches url and does not hit outer tap',
      (tester) async {
    var outer = 0;
    await tester.pumpWidget(host(const LinkifiedText('go https://a.com now'),
        onOuterTap: () => outer++));
    await tester.tapOnText(find.textRange.ofSubstring('https://a.com'));
    await tester.pump();
    expect(launcher.launched, ['https://a.com']);
    expect(outer, 0);
  });

  testWidgets('tapping plain text reaches outer tap', (tester) async {
    var outer = 0;
    await tester.pumpWidget(host(const LinkifiedText('go https://a.com now'),
        onOuterTap: () => outer++));
    final box = tester.getTopLeft(find.byType(LinkifiedText));
    await tester.tapAt(box + const Offset(2, 8));
    await tester.pump();
    expect(outer, 1);
    expect(launcher.launched, isEmpty);
  });

  testWidgets('maxLines and overflow are honoured', (tester) async {
    await tester.pumpWidget(host(const SizedBox(
      width: 100,
      child: LinkifiedText('https://a.com/very/long/path/that/overflows',
          maxLines: 1, overflow: TextOverflow.ellipsis),
    )));
    final rich = tester.widget<RichText>(find.byType(RichText).first);
    expect(rich.maxLines, 1);
    expect(rich.overflow, TextOverflow.ellipsis);
  });
}
