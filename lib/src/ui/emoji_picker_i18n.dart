import 'package:flutter/material.dart';

import '../search/emoji_search.dart';
import 'emoji_grid.dart';

/// 다국어 이모지 피커 위젯.
///
/// 검색창이 항상 노출되며, 입력 즉시 아래 그리드가 실시간으로 좁혀진다.
/// (별도 검색 화면으로 전환하지 않는 것이 이 피커의 설계 원칙)
/// 검색 중에는 카테고리 바를 숨기고, 검색어를 지우면 보던 카테고리로 돌아온다.
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
///   categoryLabels: kEmojiGroupNamesKo, // 탭 툴팁·접근성 라벨
/// )
/// ```
class EmojiPickerI18n extends StatefulWidget {
  const EmojiPickerI18n({
    super.key,
    required this.search,
    required this.onEmojiSelected,
    this.categoryLabels,
    this.columns = 8,
    this.emojiSize = 28,
    this.searchHintText = 'Search',
    this.noResultsText = ':(',
  });

  /// 데이터·검색을 담당하는 엔진. 색인 구축 비용이 있으므로
  /// 앱에서 만들어 재사용하는 것을 권장.
  final EmojiSearch search;

  final OnEmojiSelected onEmojiSelected;

  /// 카테고리 이름 목록 (인덱스 = 그룹 번호). 데이터 파일의
  /// kEmojiGroupNames* 상수를 넘기면 탭 툴팁·접근성 라벨로 쓰인다.
  final List<String>? categoryLabels;

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
  final _pageController = PageController();
  int _currentPage = 0;

  /// 그룹 번호 → 탭 아이콘 (아이콘은 언어와 무관해 코드에 둔다)
  static const _groupIcons = <int, IconData>{
    0: Icons.tag_faces, // 웃는 얼굴과 감정
    1: Icons.accessibility, // 사람과 몸
    2: Icons.extension, // 구성 요소 (일반적으로 데이터에 없음)
    3: Icons.pets, // 동물과 자연
    4: Icons.fastfood, // 음식 및 음료
    5: Icons.directions_car, // 여행 및 장소
    6: Icons.sports_soccer, // 액티비티
    7: Icons.lightbulb_outline, // 사물
    8: Icons.emoji_symbols, // 기호
    9: Icons.flag, // 플래그
  };

  @override
  void initState() {
    super.initState();
    // 입력 즉시 재검색 — 엔진이 1ms 미만이라 디바운스 불필요
    _queryController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _queryController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  bool get _isSearching => _queryController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchField(),
        if (!_isSearching) _buildCategoryBar(),
        Expanded(
          child: _isSearching ? _buildSearchResults() : _buildCategoryPages(),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: TextField(
        controller: _queryController,
        decoration: InputDecoration(
          hintText: widget.searchHintText,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear',
                  onPressed: _queryController.clear,
                )
              : null,
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBar() {
    final groups = widget.search.groups;
    final selectedColor = Theme.of(context).colorScheme.primary;
    final unselectedColor = Theme.of(context).disabledColor;

    return Row(
      children: [
        for (var i = 0; i < groups.length; i++)
          Expanded(
            child: IconButton(
              onPressed: () => _onCategoryTap(i),
              tooltip: widget.categoryLabels != null &&
                      groups[i] < widget.categoryLabels!.length
                  ? widget.categoryLabels![groups[i]]
                  : null,
              icon: Icon(
                _groupIcons[groups[i]] ?? Icons.emoji_emotions,
                size: 20,
                color: i == _currentPage ? selectedColor : unselectedColor,
              ),
            ),
          ),
      ],
    );
  }

  void _onCategoryTap(int pageIndex) {
    _pageController.jumpToPage(pageIndex);
    setState(() => _currentPage = pageIndex);
  }

  Widget _buildCategoryPages() {
    final groups = widget.search.groups;
    return PageView.builder(
      controller: _pageController,
      itemCount: groups.length,
      onPageChanged: (index) => setState(() => _currentPage = index),
      itemBuilder: (context, index) => EmojiGrid(
        key: ValueKey(groups[index]),
        emojis: widget.search.emojisOfGroup(groups[index]),
        onEmojiSelected: widget.onEmojiSelected,
        columns: widget.columns,
        emojiSize: widget.emojiSize,
      ),
    );
  }

  Widget _buildSearchResults() {
    return EmojiGrid(
      emojis: widget.search.search(_queryController.text.trim()),
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
    );
  }
}
