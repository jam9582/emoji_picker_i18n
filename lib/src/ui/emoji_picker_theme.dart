import 'package:flutter/material.dart';

/// 피커 색상 테마.
///
/// 지정하지 않은 값은 앱의 [ThemeData]([ColorScheme])에서 자동으로 가져온다.
/// 즉 기본 상태로도 앱의 라이트/다크 모드와 브랜드 색을 따라가며,
/// 특정 부분만 바꾸고 싶을 때 해당 필드만 지정하면 된다.
///
/// ```dart
/// EmojiPickerI18n(
///   theme: const EmojiPickerTheme(
///     searchFieldColor: Color(0xFFF0F0F0),
///     selectedTabColor: Colors.teal,
///   ),
///   ...
/// )
/// ```
class EmojiPickerTheme {
  const EmojiPickerTheme({
    this.backgroundColor,
    this.searchFieldColor,
    this.selectedTabColor,
    this.unselectedTabColor,
    this.skinToneDialogColor,
    this.placeholderColor,
  });

  /// 피커 전체 배경색. 미지정 시 투명 (앱 배경이 비침)
  final Color? backgroundColor;

  /// 검색창 채움색. 미지정 시 [ColorScheme.surfaceContainerHighest]
  final Color? searchFieldColor;

  /// 선택된 카테고리 탭의 아이콘·배경색. 미지정 시 [ColorScheme.primary]
  final Color? selectedTabColor;

  /// 선택되지 않은 탭 아이콘색. 미지정 시 [ThemeData.disabledColor]
  final Color? unselectedTabColor;

  /// 피부색 선택 팝업의 배경색. 미지정 시 Material 기본 표면색
  final Color? skinToneDialogColor;

  /// 안내 문구(결과 없음·최근 없음) 색. 미지정 시 [ThemeData.disabledColor]
  final Color? placeholderColor;
}
