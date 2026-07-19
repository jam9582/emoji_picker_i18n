/// 이모지 한 개의 정보.
///
/// [char]는 화면 표시용 원본 문자열로, 이모지 표시 지정자(U+FE0F) 등이
/// 붙어 있을 수 있다. 외부 문자열과 비교할 때는 normalize.dart 의
/// normalizeEmoji 를 거칠 것.
class Emoji {
  const Emoji({
    required this.char,
    required this.group,
    required this.skins,
    required this.label,
    required this.tags,
    this.version = 0,
    this.skinVersions = const [],
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

  /// 이 이모지가 추가된 유니코드 이모지 버전 (예: 🥳 11, 🫡 14).
  /// 구형 기기가 지원하는 버전과 비교해 표시 여부를 거를 때 쓴다.
  final double version;

  /// [skins]와 같은 인덱스의 버전 목록. 변형이 기본형보다 늦게
  /// 추가되기도 한다 (🤝는 3이지만 🤝🏻는 14).
  final List<double> skinVersions;

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
    final version = double.parse(commonParts[2]);

    // 피부색 변형: 'char' 또는 'char@버전' (기본형과 버전이 다를 때)
    final skins = <String>[];
    final skinVersions = <double>[];
    if (commonParts.length > 3) {
      for (final token in commonParts[3].split(',')) {
        final at = token.indexOf('@');
        if (at == -1) {
          skins.add(token);
          skinVersions.add(version);
        } else {
          skins.add(token.substring(0, at));
          skinVersions.add(double.parse(token.substring(at + 1)));
        }
      }
    }

    return Emoji(
      char: commonParts[0],
      group: int.parse(commonParts[1]),
      version: version,
      skins: skins,
      skinVersions: skinVersions,
      label: localeParts.first,
      tags: localeParts.sublist(1),
    );
  });
}
