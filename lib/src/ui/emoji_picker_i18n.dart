import 'package:flutter/material.dart';

import '../search/emoji_search.dart';
import 'emoji_grid.dart';

/// 다국어 이모지 피커 위젯.
///
/// 현재 단계: 전체 이모지 그리드만 표시 (카테고리 탭·검색창·피부색은
/// 이후 단계에서 이 위에 얹는다).
///
/// ```dart
/// final search = EmojiSearch(
///   common: kEmojiCommon,
///   locales: [kEmojiLocaleKo, kEmojiLocaleEn],
/// );
///
/// EmojiPickerI18n(
///   search: search,
///   onEmojiSelected: (emoji) => print(emoji.char),
/// )
/// ```
class EmojiPickerI18n extends StatelessWidget {
  const EmojiPickerI18n({
    super.key,
    required this.search,
    required this.onEmojiSelected,
    this.columns = 8,
    this.emojiSize = 28,
  });

  /// 데이터·검색을 담당하는 엔진. 색인 구축 비용이 있으므로
  /// 앱에서 만들어 재사용하는 것을 권장.
  final EmojiSearch search;

  final OnEmojiSelected onEmojiSelected;

  final int columns;

  final double emojiSize;

  @override
  Widget build(BuildContext context) {
    return EmojiGrid(
      emojis: search.emojis,
      onEmojiSelected: onEmojiSelected,
      columns: columns,
      emojiSize: emojiSize,
    );
  }
}
