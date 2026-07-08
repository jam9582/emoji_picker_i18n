import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:emoji_picker_i18n/emoji_picker_i18n.dart';
import 'package:emoji_picker_i18n/locales/en.dart';
import 'package:emoji_picker_i18n/locales/ko.dart';

void main() {
  final search = EmojiSearch(
    common: kEmojiCommon,
    locales: [kEmojiLocaleKo, kEmojiLocaleEn],
  );

  Widget wrap(Widget child) =>
      MaterialApp(home: Scaffold(body: child));

  testWidgets('그리드에 이모지가 표준 순서로 표시된다', (tester) async {
    await tester.pumpWidget(wrap(
      EmojiPickerI18n(search: search, onEmojiSelected: (_) {}),
    ));
    // 표준 순서 1번 😀이 첫 화면에 보인다
    expect(find.text('😀'), findsOneWidget);
  });

  testWidgets('이모지를 탭하면 콜백으로 전달된다', (tester) async {
    Emoji? selected;
    await tester.pumpWidget(wrap(
      EmojiPickerI18n(
        search: search,
        onEmojiSelected: (emoji) => selected = emoji,
      ),
    ));
    await tester.tap(find.text('😀'));
    expect(selected, isNotNull);
    expect(selected!.char, '😀');
    expect(selected!.label, isNotEmpty); // 대표 언어(ko) 이름 포함
  });

  testWidgets('빈 목록이면 placeholder를 보여준다', (tester) async {
    await tester.pumpWidget(wrap(
      EmojiGrid(
        emojis: const [],
        onEmojiSelected: (_) {},
        emptyPlaceholder: const Text('결과 없음'),
      ),
    ));
    expect(find.text('결과 없음'), findsOneWidget);
  });
}
