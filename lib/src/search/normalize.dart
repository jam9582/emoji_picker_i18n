// 이모지 표기 정규화 (기획서 5-1절)
//
// 유니코드는 같은 이모지에 복수의 유효 표기를 허용한다.
// 예: 🐈(U+1F408)와 🐈+U+FE0F 는 화면상 동일하지만 문자열로는 다름.
// 출처가 다른 이모지 문자열(키보드 입력, 타 라이브러리 저장값 등)을
// 우리 데이터와 비교할 때는 반드시 양쪽을 이 함수로 정규화할 것.
//
// 주의: 화면 표시에는 원본을 그대로 쓸 것. 표시 지정자를 지운 문자열은
// 일부 이모지(☎ 등)가 흑백 기호로 그려질 수 있다.

/// 비교 목적으로 이모지 문자열에서 보이지 않는 표시 지정자를 제거한다.
///
/// 제거 대상:
/// - U+FE0F (이모지 스타일로 표시) / U+FE0E (텍스트 스타일로 표시)
String normalizeEmoji(String emoji) {
  return String.fromCharCodes(
    emoji.runes.where((r) => r != 0xFE0F && r != 0xFE0E),
  );
}

/// 두 이모지 문자열이 표기 차이를 무시하고 같은 이모지인지 비교.
bool sameEmoji(String a, String b) => normalizeEmoji(a) == normalizeEmoji(b);
