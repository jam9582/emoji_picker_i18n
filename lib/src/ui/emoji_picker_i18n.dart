import 'package:flutter/material.dart';

import '../emoji.dart';
import '../recents/recent_emoji_storage.dart';
import '../search/emoji_search.dart';
import '../search/normalize.dart';
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
    this.enableSkinTones = true,
    this.enableRecents = true,
    this.recentsStorage,
    this.recentsLimit = 28,
    this.recentsLabel = 'Recents',
    this.noRecentsText = 'No recents yet',
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

  /// 피부색 변형 보유 이모지의 롱프레스 선택 기능
  final bool enableSkinTones;

  /// 최근 사용 탭 표시 여부
  final bool enableRecents;

  /// 최근 사용 저장소. 미지정 시 shared_preferences 영구 저장
  /// ([PrefsRecentEmojiStorage])이 기본값. 앱의 DB 등 다른 곳에
  /// 저장하려면 [RecentEmojiStorage] 구현을 주입할 것.
  final RecentEmojiStorage? recentsStorage;

  /// 최근 사용 보관 개수
  final int recentsLimit;

  /// 최근 사용 탭의 툴팁·접근성 라벨
  final String recentsLabel;

  /// 최근 사용이 비었을 때 표시할 문구
  final String noRecentsText;

  @override
  State<EmojiPickerI18n> createState() => _EmojiPickerI18nState();
}

class _EmojiPickerI18nState extends State<EmojiPickerI18n> {
  final _queryController = TextEditingController();
  late final PageController _pageController;
  late int _currentPage;
  OverlayEntry? _skinToneOverlay;

  late final RecentEmojiStorage _recentsStorage;
  List<Emoji> _recents = [];

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

  bool get _hasRecentsTab => widget.enableRecents;

  @override
  void initState() {
    super.initState();
    // 시작 페이지는 스마일리 — 최근 사용은 첫 방문 시 비어 있어서 빈 탭으로
    // 시작하는 것보다 자연스럽다
    _currentPage = _hasRecentsTab ? 1 : 0;
    _pageController = PageController(initialPage: _currentPage);

    // 입력 즉시 재검색 — 엔진이 1ms 미만이라 디바운스 불필요
    _queryController.addListener(() => setState(() {}));

    _recentsStorage = widget.recentsStorage ?? const PrefsRecentEmojiStorage();
    if (_hasRecentsTab) {
      _recentsStorage.load().then((chars) {
        if (!mounted) return;
        setState(() {
          // 데이터에 없는 문자열(구버전 잔재 등)은 조용히 걸러낸다
          _recents = chars
              .map(widget.search.findByChar)
              .whereType<Emoji>()
              .toList();
        });
      });
    }
  }

  @override
  void dispose() {
    _removeSkinToneOverlay();
    _queryController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  bool get _isSearching => _queryController.text.trim().isNotEmpty;

  // ---- 선택 처리 ----

  void _handleEmojiSelected(Emoji emoji) {
    _recordRecent(emoji);
    widget.onEmojiSelected(emoji);
  }

  /// 최근 사용 기록. 피부색 변형은 기본형으로 저장하고,
  /// 표기 차이를 무시하고 중복을 제거한 뒤 맨 앞에 넣는다.
  void _recordRecent(Emoji emoji) {
    if (!_hasRecentsTab) return;

    final base = widget.search.findByChar(emoji.char) ?? emoji;
    _recents.removeWhere((e) => sameEmoji(e.char, base.char));
    _recents.insert(0, base);
    if (_recents.length > widget.recentsLimit) {
      _recents.length = widget.recentsLimit;
    }
    _recentsStorage.save([for (final e in _recents) e.char]);

    // 최근 사용 탭을 보고 있는 중에는 순서가 눈앞에서 뒤바뀌지 않게
    // 화면 갱신을 미룬다 (다른 탭에 다녀오면 반영됨)
    if (_currentPage != 0 && mounted) {
      setState(() {});
    }
  }

  // ---- 피부색 오버레이 ----

  void _removeSkinToneOverlay() {
    _skinToneOverlay?.remove();
    _skinToneOverlay = null;
  }

  /// 롱프레스된 셀 바로 위에 기본형 + 피부색 변형들을 가로로 띄운다.
  /// 바깥을 탭하면 닫히고, 변형을 탭하면 선택 콜백 후 닫힌다.
  void _showSkinToneOverlay(Emoji emoji, Rect cellRect) {
    _removeSkinToneOverlay();

    final variants = [emoji.char, ...emoji.skins];
    final cellSize = widget.emojiSize + 16;
    final overlayWidth = variants.length * cellSize + 8;
    final screenWidth = MediaQuery.of(context).size.width;
    final left = (cellRect.center.dx - overlayWidth / 2)
        .clamp(4.0, screenWidth - overlayWidth - 4);
    final top = (cellRect.top - cellSize - 12).clamp(4.0, double.infinity);

    _skinToneOverlay = OverlayEntry(
      builder: (_) => Positioned(
        left: left,
        top: top,
        child: TapRegion(
          onTapOutside: (_) => _removeSkinToneOverlay(),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final variant in variants)
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        _handleEmojiSelected(Emoji(
                          char: variant,
                          group: emoji.group,
                          skins: const [],
                          label: emoji.label,
                          tags: emoji.tags,
                        ));
                        _removeSkinToneOverlay();
                      },
                      child: SizedBox(
                        width: cellSize,
                        height: cellSize,
                        child: Center(
                          child: Text(
                            variant,
                            style: TextStyle(fontSize: widget.emojiSize),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_skinToneOverlay!);
  }

  // ---- 화면 구성 ----

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

    Widget tab({
      required int pageIndex,
      required IconData icon,
      String? tooltip,
    }) {
      return Expanded(
        child: IconButton(
          onPressed: () => _onCategoryTap(pageIndex),
          tooltip: tooltip,
          icon: Icon(
            icon,
            size: 20,
            color: pageIndex == _currentPage ? selectedColor : unselectedColor,
          ),
        ),
      );
    }

    final offset = _hasRecentsTab ? 1 : 0;
    return Row(
      children: [
        if (_hasRecentsTab)
          tab(
            pageIndex: 0,
            icon: Icons.access_time,
            tooltip: widget.recentsLabel,
          ),
        for (var i = 0; i < groups.length; i++)
          tab(
            pageIndex: i + offset,
            icon: _groupIcons[groups[i]] ?? Icons.emoji_emotions,
            tooltip: widget.categoryLabels != null &&
                    groups[i] < widget.categoryLabels!.length
                ? widget.categoryLabels![groups[i]]
                : null,
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
    final offset = _hasRecentsTab ? 1 : 0;

    return PageView.builder(
      controller: _pageController,
      itemCount: groups.length + offset,
      onPageChanged: (index) => setState(() => _currentPage = index),
      itemBuilder: (context, index) {
        if (_hasRecentsTab && index == 0) {
          return EmojiGrid(
            key: const ValueKey('recents'),
            emojis: _recents,
            onEmojiSelected: _handleEmojiSelected,
            onEmojiLongPressed:
                widget.enableSkinTones ? _showSkinToneOverlay : null,
            columns: widget.columns,
            emojiSize: widget.emojiSize,
            emptyPlaceholder: Text(
              widget.noRecentsText,
              style: TextStyle(color: Theme.of(context).disabledColor),
            ),
          );
        }
        final group = groups[index - offset];
        return EmojiGrid(
          key: ValueKey(group),
          emojis: widget.search.emojisOfGroup(group),
          onEmojiSelected: _handleEmojiSelected,
          onEmojiLongPressed:
              widget.enableSkinTones ? _showSkinToneOverlay : null,
          columns: widget.columns,
          emojiSize: widget.emojiSize,
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return EmojiGrid(
      emojis: widget.search.search(_queryController.text.trim()),
      onEmojiSelected: _handleEmojiSelected,
      onEmojiLongPressed:
          widget.enableSkinTones ? _showSkinToneOverlay : null,
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
