import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:emoji_picker_i18n/emoji_picker_i18n.dart';
import 'package:emoji_picker_i18n/locales/en.dart';
import 'package:emoji_picker_i18n/locales/ko.dart';

void main() {
  final search = EmojiSearch(
    common: kEmojiCommon,
    locales: [kEmojiLocaleKo, kEmojiLocaleEn],
  );

  // 기본 저장소(shared_preferences)를 테스트마다 빈 상태로 초기화
  setUp(() => SharedPreferences.setMockInitialValues({}));

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

  group('카테고리 탭', () {
    testWidgets('데이터에 있는 그룹 수만큼 탭이 생긴다', (tester) async {
      await tester.pumpWidget(wrap(
        EmojiPickerI18n(search: search, onEmojiSelected: (_) {}),
      ));
      // 컴포넌트(그룹 2) 제외 9개 그룹 → 아이콘 9개
      expect(search.groups.length, 9);
      expect(find.byIcon(Icons.pets), findsOneWidget);
      expect(find.byIcon(Icons.flag), findsOneWidget);
    });

    testWidgets('동물 탭을 누르면 동물 페이지로 이동한다', (tester) async {
      await tester.pumpWidget(wrap(
        EmojiPickerI18n(search: search, onEmojiSelected: (_) {}),
      ));
      expect(find.text('😀'), findsOneWidget); // 시작은 스마일리

      await tester.tap(find.byIcon(Icons.pets));
      await tester.pumpAndSettle();

      expect(find.text('🐵'), findsOneWidget); // 동물 그룹 첫 이모지
      expect(find.text('😀'), findsNothing);
    });

    testWidgets('검색 중에는 카테고리 바가 숨는다', (tester) async {
      await tester.pumpWidget(wrap(
        EmojiPickerI18n(search: search, onEmojiSelected: (_) {}),
      ));
      expect(find.byIcon(Icons.pets), findsOneWidget);

      await tester.enterText(find.byType(TextField), '고양이');
      await tester.pump();
      expect(find.byIcon(Icons.pets), findsNothing);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();
      expect(find.byIcon(Icons.pets), findsOneWidget); // 지우면 복귀
    });

    testWidgets('테마 오버라이드: 선택 탭 색이 지정한 색으로 바뀐다', (tester) async {
      await tester.pumpWidget(wrap(
        EmojiPickerI18n(
          search: search,
          onEmojiSelected: (_) {},
          theme: const EmojiPickerTheme(selectedTabColor: Colors.teal),
        ),
      ));
      // 시작 페이지(스마일리) 탭 아이콘이 지정 색이어야 함
      final icon = tester.widget<Icon>(find.byIcon(Icons.tag_faces));
      expect(icon.color, Colors.teal);
    });

    testWidgets('카테고리 이름이 탭 툴팁으로 붙는다', (tester) async {
      await tester.pumpWidget(wrap(
        EmojiPickerI18n(
          search: search,
          onEmojiSelected: (_) {},
          categoryLabels: kEmojiGroupNamesKo,
        ),
      ));
      expect(find.byTooltip('동물과 자연'), findsOneWidget);
    });
  });

  group('피부색 오버레이', () {
    Future<void> goToPeopleTab(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.accessibility));
      await tester.pumpAndSettle();
    }

    testWidgets('롱프레스하면 피부색 변형 팝업이 뜬다', (tester) async {
      await tester.pumpWidget(wrap(
        EmojiPickerI18n(search: search, onEmojiSelected: (_) {}),
      ));
      await goToPeopleTab(tester);

      await tester.longPress(find.text('👋'));
      await tester.pumpAndSettle();

      expect(find.text('👋🏻'), findsOneWidget);
      expect(find.text('👋🏿'), findsOneWidget);
    });

    testWidgets('변형을 탭하면 그 변형이 선택되고 팝업이 닫힌다', (tester) async {
      Emoji? selected;
      await tester.pumpWidget(wrap(
        EmojiPickerI18n(
          search: search,
          onEmojiSelected: (emoji) => selected = emoji,
        ),
      ));
      await goToPeopleTab(tester);

      await tester.longPress(find.text('👋'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('👋🏽'));
      await tester.pumpAndSettle();

      expect(selected!.char, '👋🏽');
      expect(find.text('👋🏽'), findsNothing); // 팝업 닫힘
    });

    testWidgets('변형 없는 이모지는 롱프레스해도 팝업이 없다', (tester) async {
      await tester.pumpWidget(wrap(
        EmojiPickerI18n(search: search, onEmojiSelected: (_) {}),
      ));
      await tester.longPress(find.text('😀'));
      await tester.pumpAndSettle();

      expect(find.byType(TapRegion), findsNothing);
    });

    testWidgets('enableSkinTones: false면 롱프레스가 비활성', (tester) async {
      await tester.pumpWidget(wrap(
        EmojiPickerI18n(
          search: search,
          onEmojiSelected: (_) {},
          enableSkinTones: false,
        ),
      ));
      await goToPeopleTab(tester);

      await tester.longPress(find.text('👋'));
      await tester.pumpAndSettle();

      expect(find.text('👋🏻'), findsNothing);
    });
  });

  group('최근 사용', () {
    Future<void> goToRecentsTab(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.access_time));
      await tester.pumpAndSettle();
    }

    testWidgets('처음에는 비어 있고 안내 문구가 보인다', (tester) async {
      await tester.pumpWidget(wrap(
        EmojiPickerI18n(
          search: search,
          onEmojiSelected: (_) {},
          noRecentsText: '아직 없어요',
        ),
      ));
      await tester.pumpAndSettle();
      await goToRecentsTab(tester);

      expect(find.text('아직 없어요'), findsOneWidget);
    });

    testWidgets('선택한 이모지가 최근 사용 맨 앞에 쌓인다', (tester) async {
      await tester.pumpWidget(wrap(
        EmojiPickerI18n(search: search, onEmojiSelected: (_) {}),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('😀'));
      await tester.tap(find.text('😃'));
      await goToRecentsTab(tester);

      final recentsGrid = find.byKey(const ValueKey('recents'));
      final texts = tester
          .widgetList<Text>(find.descendant(
              of: recentsGrid, matching: find.byType(Text)))
          .map((t) => t.data)
          .toList();
      expect(texts, ['😃', '😀']); // 최신이 앞
    });

    testWidgets('같은 이모지를 다시 선택하면 중복 없이 맨 앞으로 온다', (tester) async {
      await tester.pumpWidget(wrap(
        EmojiPickerI18n(search: search, onEmojiSelected: (_) {}),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('😀'));
      await tester.tap(find.text('😃'));
      await tester.tap(find.text('😀')); // 재선택
      await goToRecentsTab(tester);

      final recentsGrid = find.byKey(const ValueKey('recents'));
      final texts = tester
          .widgetList<Text>(find.descendant(
              of: recentsGrid, matching: find.byType(Text)))
          .map((t) => t.data)
          .toList();
      expect(texts, ['😀', '😃']);
    });

    testWidgets('피부색 변형을 선택해도 기본형으로 저장된다', (tester) async {
      await tester.pumpWidget(wrap(
        EmojiPickerI18n(search: search, onEmojiSelected: (_) {}),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.accessibility));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('👋'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('👋🏽'));
      await tester.pumpAndSettle();

      await goToRecentsTab(tester);
      final recentsGrid = find.byKey(const ValueKey('recents'));
      expect(
        find.descendant(of: recentsGrid, matching: find.text('👋')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: recentsGrid, matching: find.text('👋🏽')),
        findsNothing,
      );
    });

    testWidgets('주입한 저장소에 저장되고 다음 피커가 그걸 불러온다', (tester) async {
      final storage = MemoryRecentEmojiStorage();

      await tester.pumpWidget(wrap(
        EmojiPickerI18n(
          search: search,
          onEmojiSelected: (_) {},
          recentsStorage: storage,
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('😀'));
      await tester.pumpAndSettle();

      // 완전히 새 피커 인스턴스에 같은 저장소 주입
      await tester.pumpWidget(wrap(
        EmojiPickerI18n(
          key: UniqueKey(),
          search: search,
          onEmojiSelected: (_) {},
          recentsStorage: storage,
        ),
      ));
      await tester.pumpAndSettle();
      await goToRecentsTab(tester);

      final recentsGrid = find.byKey(const ValueKey('recents'));
      expect(
        find.descendant(of: recentsGrid, matching: find.text('😀')),
        findsOneWidget,
      );
    });

    testWidgets('recentsLimit을 넘으면 오래된 것부터 밀려난다', (tester) async {
      await tester.pumpWidget(wrap(
        EmojiPickerI18n(
          search: search,
          onEmojiSelected: (_) {},
          recentsLimit: 2,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('😀'));
      await tester.tap(find.text('😃'));
      await tester.tap(find.text('😄'));
      await goToRecentsTab(tester);

      final recentsGrid = find.byKey(const ValueKey('recents'));
      final texts = tester
          .widgetList<Text>(find.descendant(
              of: recentsGrid, matching: find.byType(Text)))
          .map((t) => t.data)
          .toList();
      expect(texts, ['😄', '😃']); // 😀은 밀려남
    });
  });
}
