/// 이모지 한 개의 정보.
///
/// [char]는 화면 표시용 원본 문자열로, 이모지 표시 지정자(U+FE0F) 등이
/// 붙어 있을 수 있다. 외부 문자열과 비교할 때는 normalize.dart 의
/// normalizeEmoji 를 거칠 것 (기획서 5-1절).
class Emoji {
  const Emoji({
    required this.char,
    required this.group,
    required this.skins,
    required this.label,
    required this.tags,
  });

  /// 이모지 문자 (예: '🐱')
  final String char;

  /// 카테고리 그룹 번호 (emojibase 기준: 0 스마일리, 3 동물, ...)
  final int group;

  /// 피부색 변형 목록 (없으면 빈 리스트)
  final List<String> skins;

  /// 대표 이름 (엔진에 넘긴 첫 번째 언어 기준)
  final String label;

  /// 검색 키워드 (첫 번째 언어 기준)
  final List<String> tags;

  @override
  String toString() => '$char($label)';
}

/// 생성된 데이터 파일(emoji_common.dart / emoji_locale_xx.dart)을
/// [Emoji] 목록으로 변환한다.
///
/// [common]: kEmojiCommon, [locale]: kEmojiLocaleKo 등 (인덱스 정렬 보장).
List<Emoji> parseEmojiData(List<String> common, List<String> locale) {
  assert(common.length == locale.length, '공통/언어 데이터 길이 불일치');
  return List.generate(common.length, (i) {
    final commonParts = common[i].split('|');
    final localeParts = locale[i].split('|');
    return Emoji(
      char: commonParts[0],
      group: int.parse(commonParts[1]),
      skins: commonParts.length > 2 ? commonParts[2].split(',') : const [],
      label: localeParts.first,
      tags: localeParts.sublist(1),
    );
  });
}
