import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/material.dart';

import '../recents/recent_emoji_storage.dart';

/// 검색창·카테고리 바를 피커의 위/아래 중 어디에 둘지.
enum PickerBarPosition { top, bottom }

/// 검색창 설정.
///
/// 색상은 [EmojiPickerTheme]에서, 그 외 문구·아이콘·배치는 여기서 다룬다.
class EmojiSearchBarConfig {
  const EmojiSearchBarConfig({
    this.show = true,
    this.position = PickerBarPosition.top,
    this.hintText = 'Search',
    this.noResultsText = ':(',
    this.textStyle,
    this.hintStyle,
    this.searchIcon = const Icon(Icons.search, size: 20),
    this.clearIcon = const Icon(Icons.clear, size: 18),
    this.padding = const EdgeInsets.fromLTRB(12, 8, 12, 4),
  });

  /// 검색창 표시 여부. 숨기면 검색 기능 없이 카테고리 탐색만 가능
  final bool show;

  /// 검색창 위치 (기본: 피커 최상단)
  final PickerBarPosition position;

  /// 안내 문구 (앱의 언어에 맞게 지정)
  final String hintText;

  /// 검색 결과가 없을 때 그리드 자리에 표시할 문구
  final String noResultsText;

  /// 입력 텍스트 스타일. 미지정 시 fontSize 15
  final TextStyle? textStyle;

  /// 안내 문구 스타일. 미지정 시 입력 텍스트와 동일 계열
  final TextStyle? hintStyle;

  /// 검색창 왼쪽 아이콘
  final Widget searchIcon;

  /// 검색어 지우기 버튼 아이콘
  final Widget clearIcon;

  /// 검색창 바깥 여백
  final EdgeInsets padding;
}

/// 카테고리 바(탭 줄) 설정.
class EmojiCategoryBarConfig {
  const EmojiCategoryBarConfig({
    this.show = true,
    this.position = PickerBarPosition.top,
    this.labels,
    this.icons,
    this.recentsIcon = Icons.access_time,
    this.iconSize = 20,
  });

  /// 카테고리 바 표시 여부. 숨겨도 그리드 좌우 스와이프는 동작
  final bool show;

  /// 카테고리 바 위치. top이면 검색창 아래, bottom이면 그리드 아래
  /// (모바일 키보드처럼 하단 탭 배치를 원할 때)
  final PickerBarPosition position;

  /// 카테고리 이름 목록 (인덱스 = 그룹 번호). 데이터 파일의
  /// kEmojiGroupNames* 상수를 넘기면 탭 툴팁·접근성 라벨로 쓰인다
  final List<String>? labels;

  /// 그룹 번호 → 탭 아이콘 오버라이드. 지정한 그룹만 바뀌고
  /// 나머지는 기본 아이콘 유지
  final Map<int, IconData>? icons;

  /// 최근 사용 탭 아이콘
  final IconData recentsIcon;

  /// 탭 아이콘 크기
  final double iconSize;
}

/// 이모지 격자 설정.
class EmojiGridConfig {
  const EmojiGridConfig({
    this.cellExtent = 44,
    this.emojiSize = 28,
    this.horizontalSpacing = 0,
    this.verticalSpacing = 0,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
    this.emojiTextStyle,
  });

  /// 셀 한 칸의 최대 크기. 열 개수를 고정하는 대신 화면 폭에 맞춰
  /// 열이 자동으로 늘어난다 (폰 세로 ~8열, 태블릿·데스크톱은 더 많이)
  final double cellExtent;

  /// 이모지 글자 크기
  final double emojiSize;

  /// 셀 사이 가로 간격
  final double horizontalSpacing;

  /// 셀 사이 세로 간격
  final double verticalSpacing;

  /// 격자 바깥 여백
  final EdgeInsets padding;

  /// 이모지 텍스트 스타일 (커스텀 이모지 폰트 지정용).
  /// fontSize는 [emojiSize]가 항상 우선한다
  final TextStyle? emojiTextStyle;
}

/// 피부색 변형 선택 설정.
class EmojiSkinToneConfig {
  const EmojiSkinToneConfig({
    this.enabled = true,
    this.longPressDelay = kLongPressTimeout,
  });

  /// 피부색 변형 보유 이모지의 롱프레스 선택 기능
  final bool enabled;

  /// 팝업이 뜨기까지 누르고 있어야 하는 시간. 기본은 Flutter 표준(500ms).
  /// 짧게 줄수록 빨리 뜨지만, 너무 짧으면 스크롤하려던 손가락에도 반응한다
  final Duration longPressDelay;
}

/// 최근 사용 탭 설정.
class EmojiRecentsConfig {
  const EmojiRecentsConfig({
    this.enabled = true,
    this.storage,
    this.limit = 28,
    this.label = 'Recents',
    this.emptyText = 'No recents yet',
  });

  /// 최근 사용 탭 표시 여부
  final bool enabled;

  /// 최근 사용 저장소. 미지정 시 shared_preferences 영구 저장
  /// ([PrefsRecentEmojiStorage])이 기본값. 앱의 DB 등 다른 곳에
  /// 저장하려면 [RecentEmojiStorage] 구현을 주입할 것
  final RecentEmojiStorage? storage;

  /// 보관 개수. 초과 시 오래된 것부터 밀려남
  final int limit;

  /// 최근 사용 탭의 툴팁·접근성 라벨
  final String label;

  /// 최근 사용이 비었을 때 표시할 문구
  final String emptyText;
}
