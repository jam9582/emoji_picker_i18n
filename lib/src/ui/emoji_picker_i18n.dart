import 'package:flutter/material.dart';

import '../search/emoji_search.dart';
import 'emoji_grid.dart';

/// 다국어 이모지 피커 위젯.
///
/// 검색창이 항상 노출되며, 입력 즉시 아래 그리드가 실시간으로 좁혀진다.
/// (별도 검색 화면으로 전환하지 않는 것이 이 피커의 설계 원칙)
///
/// 현재 단계: 검색창 + 그리드. 카테고리 탭·피부색 오버레이는 이후 단계.
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
class EmojiPickerI18n extends StatefulWidget {
  const EmojiPickerI18n({
    super.key,
    required this.search,
    required this.onEmojiSelected,
    this.columns = 8,
    this.emojiSize = 28,
    this.searchHintText = 'Search',
    this.noResultsText = ':(',
  });

  /// 데이터·검색을 담당하는 엔진. 색인 구축 비용이 있으므로
  /// 앱에서 만들어 재사용하는 것을 권장.
  final EmojiSearch search;

  final OnEmojiSelected onEmojiSelected;

  final int columns;

  final double emojiSize;

  /// 검색창 안내 문구 (앱의 언어에 맞게 지정)
  final String searchHintText;

  /// 검색 결과가 없을 때 표시할 문구
  final String noResultsText;

  @override
  State<EmojiPickerI18n> createState() => _EmojiPickerI18nState();
}

class _EmojiPickerI18nState extends State<EmojiPickerI18n> {
  final _queryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 입력 즉시 재검색 — 엔진이 1ms 미만이라 디바운스 불필요
    _queryController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _queryController.text.trim();
    final emojis =
        query.isEmpty ? widget.search.emojis : widget.search.search(query);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: TextField(
            controller: _queryController,
            decoration: InputDecoration(
              hintText: widget.searchHintText,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear',
                      onPressed: _queryController.clear,
                    ),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Expanded(
          child: EmojiGrid(
            emojis: emojis,
            onEmojiSelected: widget.onEmojiSelected,
            columns: widget.columns,
            emojiSize: widget.emojiSize,
            emptyPlaceholder: Text(
              widget.noResultsText,
              style: TextStyle(
                fontSize: widget.emojiSize,
                color: Theme.of(context).disabledColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
