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

  group('검색창', () {
    testWidgets('한국어 타이핑 즉시 그리드가 좁혀진다', (tester) async {
      await tester.pumpWidget(wrap(
        EmojiPickerI18n(search: search, onEmojiSelected: (_) {}),
      ));
      expect(find.text('😀'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '고양이');
      await tester.pump();

      expect(find.text('🐈️'), findsOneWidget); // 1순위 결과
      expect(find.text('😀'), findsNothing); // 무관한 이모지는 사라짐
    });

    testWidgets('초성 검색도 화면에서 동작한다', (tester) async {
      await tester.pumpWidget(wrap(
        EmojiPickerI18n(search: search, onEmojiSelected: (_) {}),
      ));
      await tester.enterText(find.byType(TextField), 'ㄱㅇㅇ');
      await tester.pump();

      expect(find.text('🐈️'), findsOneWidget);
    });

    testWidgets('지우기 버튼을 누르면 전체 그리드로 복원된다', (tester) async {
      await tester.pumpWidget(wrap(
        EmojiPickerI18n(search: search, onEmojiSelected: (_) {}),
      ));
      await tester.enterText(find.byType(TextField), '고양이');
      await tester.pump();
      expect(find.text('😀'), findsNothing);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(find.text('😀'), findsOneWidget);
    });

    testWidgets('결과 없는 검색어는 안내 문구를 보여준다', (tester) async {
      await tester.pumpWidget(wrap(
        EmojiPickerI18n(
          search: search,
          onEmojiSelected: (_) {},
          noResultsText: '결과 없음',
        ),
      ));
      await tester.enterText(find.byType(TextField), '쀍쀍쀍');
      await tester.pump();

      expect(find.text('결과 없음'), findsOneWidget);
    });
  });
}
