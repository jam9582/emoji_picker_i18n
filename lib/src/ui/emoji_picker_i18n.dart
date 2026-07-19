import 'package:flutter/material.dart';

import '../emoji.dart';
import '../recents/recent_emoji_storage.dart';
import '../search/emoji_search.dart';
import '../search/normalize.dart';
import 'emoji_grid.dart';
import 'emoji_picker_config.dart';
import 'emoji_picker_theme.dart';

/// 다국어 이모지 피커 위젯.
///
/// 검색창이 항상 노출되며, 입력 즉시 아래 그리드가 실시간으로 좁혀진다.
/// (별도 검색 화면으로 전환하지 않는 것이 이 피커의 설계 원칙)
/// 검색 중에는 카테고리 바를 숨기고, 검색어를 지우면 보던 카테고리로 돌아온다.
///
/// 색상은 [EmojiPickerTheme], 부위별 세부 설정은 [EmojiSearchBarConfig]·
/// [EmojiCategoryBarConfig]·[EmojiGridConfig]·[EmojiSkinToneConfig]·
/// [EmojiRecentsConfig]로 조정한다. 전부 기본값으로도 동작한다.
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
///   searchBarConfig: const EmojiSearchBarConfig(hintText: '검색'),
///   categoryBarConfig: const EmojiCategoryBarConfig(
///     labels: kEmojiGroupNamesKo, // 탭 툴팁·접근성 라벨
///   ),
/// )
/// ```
class EmojiPickerI18n extends StatefulWidget {
  const EmojiPickerI18n({
    super.key,
    required this.search,
    required this.onEmojiSelected,
    this.theme = const EmojiPickerTheme(),
    this.searchBarConfig = const EmojiSearchBarConfig(),
    this.categoryBarConfig = const EmojiCategoryBarConfig(),
    this.gridConfig = const EmojiGridConfig(),
    this.skinToneConfig = const EmojiSkinToneConfig(),
    this.recentsConfig = const EmojiRecentsConfig(),
  });

  /// 데이터·검색을 담당하는 엔진. 색인 구축 비용이 있으므로
  /// 앱에서 만들어 재사용하는 것을 권장.
  final EmojiSearch search;

  final OnEmojiSelected onEmojiSelected;

  /// 색상 테마. 미지정 필드는 앱 테마([ColorScheme])를 자동으로 따른다.
  final EmojiPickerTheme theme;

  /// 검색창 설정 (표시·위치·문구·아이콘·스타일)
  final EmojiSearchBarConfig searchBarConfig;

  /// 카테고리 바 설정 (표시·위치·아이콘·라벨)
  final EmojiCategoryBarConfig categoryBarConfig;

  /// 격자 설정 (크기·간격·여백·텍스트 스타일)
  final EmojiGridConfig gridConfig;

  /// 피부색 변형 선택 설정
  final EmojiSkinToneConfig skinToneConfig;

  /// 최근 사용 설정 (표시·저장소·보관 개수·문구).
  /// 저장소는 첫 빌드 때 한 번만 읽으므로 도중 교체는 반영되지 않는다.
  final EmojiRecentsConfig recentsConfig;

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

  /// 그룹 번호 → 탭 기본 아이콘 (아이콘은 언어와 무관해 코드에 둔다)
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

  bool get _hasRecentsTab => widget.recentsConfig.enabled;

  @override
  void initState() {
    super.initState();
    // 시작 페이지는 스마일리 — 최근 사용은 첫 방문 시 비어 있어서 빈 탭으로
    // 시작하는 것보다 자연스럽다
    _currentPage = _hasRecentsTab ? 1 : 0;
    _pageController = PageController(initialPage: _currentPage);

    // 입력 즉시 재검색 — 엔진이 1ms 미만이라 디바운스 불필요
    _queryController.addListener(() => setState(() {}));

    _recentsStorage =
        widget.recentsConfig.storage ?? const PrefsRecentEmojiStorage();
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

  bool get _isSearching =>
      widget.searchBarConfig.show && _queryController.text.trim().isNotEmpty;

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
    if (_recents.length > widget.recentsConfig.limit) {
      _recents.length = widget.recentsConfig.limit;
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

    final emojiSize = widget.gridConfig.emojiSize;
    final emojiStyle = (widget.gridConfig.emojiTextStyle ?? const TextStyle())
        .copyWith(fontSize: emojiSize);
    final variants = [emoji.char, ...emoji.skins];
    final cellSize = emojiSize + 16;
    final overlayWidth = variants.length * cellSize + 8;
    final screenWidth = MediaQuery.of(context).size.width;
    final left = (cellRect.center.dx - overlayWidth / 2).clamp(
      4.0,
      screenWidth - overlayWidth - 4,
    );
    final top = (cellRect.top - cellSize - 12).clamp(4.0, double.infinity);

    _skinToneOverlay = OverlayEntry(
      builder: (_) => Positioned(
        left: left,
        top: top,
        child: TapRegion(
          onTapOutside: (_) => _removeSkinToneOverlay(),
          child: Material(
            elevation: 4,
            color: widget.theme.skinToneDialogColor,
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
                        _handleEmojiSelected(
                          Emoji(
                            char: variant,
                            group: emoji.group,
                            skins: const [],
                            label: emoji.label,
                            tags: emoji.tags,
                          ),
                        );
                        _removeSkinToneOverlay();
                      },
                      child: SizedBox(
                        width: cellSize,
                        height: cellSize,
                        child: Center(
                          child: Text(variant, style: emojiStyle),
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
    final searchCfg = widget.searchBarConfig;
    final categoryCfg = widget.categoryBarConfig;
    // 검색 중에는 카테고리 바를 숨긴다 (결과 그리드에 자리를 양보)
    final showCategoryBar = categoryCfg.show && !_isSearching;

    final body = Column(
      children: [
        if (searchCfg.show && searchCfg.position == PickerBarPosition.top)
          _buildSearchField(),
        if (showCategoryBar && categoryCfg.position == PickerBarPosition.top)
          _buildCategoryBar(),
        Expanded(
          child: _isSearching ? _buildSearchResults() : _buildCategoryPages(),
        ),
        if (showCategoryBar &&
            categoryCfg.position == PickerBarPosition.bottom)
          _buildCategoryBar(),
        if (searchCfg.show && searchCfg.position == PickerBarPosition.bottom)
          _buildSearchField(),
      ],
    );
    final background = widget.theme.backgroundColor;
    return background == null
        ? body
        : ColoredBox(color: background, child: body);
  }

  Color get _placeholderColor =>
      widget.theme.placeholderColor ?? Theme.of(context).disabledColor;

  Widget _buildSearchField() {
    final cfg = widget.searchBarConfig;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: cfg.padding,
      child: TextField(
        controller: _queryController,
        style: cfg.textStyle ?? const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: cfg.hintText,
          hintStyle: cfg.hintStyle,
          prefixIcon: cfg.searchIcon,
          suffixIcon: _isSearching
              ? IconButton(
                  icon: cfg.clearIcon,
                  tooltip: 'Clear',
                  onPressed: _queryController.clear,
                )
              : null,
          filled: true,
          fillColor:
              widget.theme.searchFieldColor ?? scheme.surfaceContainerHighest,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          // 모바일 키보드 검색창처럼 테두리 없는 알약 모양
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBar() {
    final cfg = widget.categoryBarConfig;
    final groups = widget.search.groups;
    final selectedColor =
        widget.theme.selectedTabColor ?? Theme.of(context).colorScheme.primary;
    final unselectedColor =
        widget.theme.unselectedTabColor ?? Theme.of(context).disabledColor;

    Widget tab({
      required int pageIndex,
      required IconData icon,
      String? tooltip,
    }) {
      final selected = pageIndex == _currentPage;
      return Expanded(
        child: IconButton(
          onPressed: () => _onCategoryTap(pageIndex),
          tooltip: tooltip,
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            // 선택된 탭은 은은한 원형 배경으로 표시
            backgroundColor: selected
                ? selectedColor.withValues(alpha: 0.12)
                : Colors.transparent,
          ),
          icon: Icon(
            icon,
            size: cfg.iconSize,
            color: selected ? selectedColor : unselectedColor,
          ),
        ),
      );
    }

    IconData iconOfGroup(int group) =>
        cfg.icons?[group] ?? _groupIcons[group] ?? Icons.emoji_emotions;

    final offset = _hasRecentsTab ? 1 : 0;
    return Row(
      children: [
        if (_hasRecentsTab)
          tab(
            pageIndex: 0,
            icon: cfg.recentsIcon,
            tooltip: widget.recentsConfig.label,
          ),
        for (var i = 0; i < groups.length; i++)
          tab(
            pageIndex: i + offset,
            icon: iconOfGroup(groups[i]),
            tooltip: cfg.labels != null && groups[i] < cfg.labels!.length
                ? cfg.labels![groups[i]]
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
            onEmojiLongPressed: widget.skinToneConfig.enabled
                ? _showSkinToneOverlay
                : null,
            config: widget.gridConfig,
            emptyPlaceholder: Text(
              widget.recentsConfig.emptyText,
              style: TextStyle(color: _placeholderColor),
            ),
          );
        }
        final group = groups[index - offset];
        return EmojiGrid(
          key: ValueKey(group),
          emojis: widget.search.emojisOfGroup(group),
          onEmojiSelected: _handleEmojiSelected,
          onEmojiLongPressed: widget.skinToneConfig.enabled
              ? _showSkinToneOverlay
              : null,
          config: widget.gridConfig,
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return EmojiGrid(
      emojis: widget.search.search(_queryController.text.trim()),
      onEmojiSelected: _handleEmojiSelected,
      onEmojiLongPressed:
          widget.skinToneConfig.enabled ? _showSkinToneOverlay : null,
      config: widget.gridConfig,
      emptyPlaceholder: Text(
        widget.searchBarConfig.noResultsText,
        style: TextStyle(
          fontSize: widget.gridConfig.emojiSize,
          color: _placeholderColor,
        ),
      ),
    );
  }
}
