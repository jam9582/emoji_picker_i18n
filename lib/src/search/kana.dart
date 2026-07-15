// 일본어 가나 정규화
//
// 히라가나(ねこ)와 가타카나(ネコ)는 소리가 같은 두 문자 체계다.
// CLDR 일본어 키워드는 단어마다 관례 표기(동물은 주로 가타카나)를 쓰는데,
// 일본어 입력기는 항상 히라가나를 먼저 내놓으므로 표기를 통일해서
// 비교해야 타이핑 즉시 검색된다.
//
// 유니코드에서 두 문자는 같은 순서로 나란히 배치되어 있어
// (ぁ U+3041 ↔ ァ U+30A1) 코드에 0x60을 더하는 산수만으로 변환된다.
// 사전 데이터 불필요 — 한글 자모 분해와 같은 원리.

const int _hiraganaStart = 0x3041; // ぁ
const int _hiraganaEnd = 0x3096; // ゖ (ゔ 포함)
const int _hiraganaIterStart = 0x309D; // ゝ (반복 기호)
const int _hiraganaIterEnd = 0x309E; // ゞ
const int _kanaOffset = 0x60;

/// 히라가나를 가타카나로 통일한 문자열 (비교·매칭 전용).
/// 가나가 아닌 글자는 그대로 통과한다.
String normalizeKana(String text) {
  final codes = text.codeUnits;
  if (!codes.any(_isHiragana)) return text;
  return String.fromCharCodes(
    codes.map((c) => _isHiragana(c) ? c + _kanaOffset : c),
  );
}

bool _isHiragana(int code) =>
    (code >= _hiraganaStart && code <= _hiraganaEnd) ||
    (code >= _hiraganaIterStart && code <= _hiraganaIterEnd);
