// 한글 초성·자모 검색 유틸
//
// 한글 완성형 음절(가~힣)은 유니코드에서 수학 공식으로 분해된다:
//   code = 0xAC00 + (초성 × 588) + (중성 × 28) + 종성
// 사전 데이터 없이 계산만으로 초성 추출·자모 분해가 가능한 이유.
//
// 지원하는 검색 형태:
//   - 초성만:        'ㄱㅇㅇ'  → 고양이
//   - 완성+초성 혼합: '고ㅇ'    → 고양이 (자모 스트림 매칭으로 처리)
//   - 치다 만 입력:   '고양ㅇ'  → 고양이
//   - 일반 부분 문자열은 이 파일이 아니라 검색 엔진의 contains 매칭이 담당

const int _syllableBase = 0xAC00; // '가'
const int _syllableCount = 11172; // 가~힣
const int _jungCount = 21;
const int _jongCount = 28;

/// 초성 19자 (유니코드 호환 자모)
const List<String> _choseong = [
  'ㄱ',
  'ㄲ',
  'ㄴ',
  'ㄷ',
  'ㄸ',
  'ㄹ',
  'ㅁ',
  'ㅂ',
  'ㅃ',
  'ㅅ',
  'ㅆ',
  'ㅇ',
  'ㅈ',
  'ㅉ',
  'ㅊ',
  'ㅋ',
  'ㅌ',
  'ㅍ',
  'ㅎ',
];

/// 중성 21자 — 겹모음은 타이핑 순서대로 분해 (ㅘ → ㅗㅏ)
const List<String> _jungseong = [
  'ㅏ',
  'ㅐ',
  'ㅑ',
  'ㅒ',
  'ㅓ',
  'ㅔ',
  'ㅕ',
  'ㅖ',
  'ㅗ',
  'ㅗㅏ',
  'ㅗㅐ',
  'ㅗㅣ',
  'ㅛ',
  'ㅜ',
  'ㅜㅓ',
  'ㅜㅔ',
  'ㅜㅣ',
  'ㅠ',
  'ㅡ',
  'ㅡㅣ',
  'ㅣ',
];

/// 종성 28자 (첫 칸은 받침 없음) — 겹받침은 타이핑 순서대로 분해 (ㄺ → ㄹㄱ)
const List<String> _jongseong = [
  '',
  'ㄱ',
  'ㄲ',
  'ㄱㅅ',
  'ㄴ',
  'ㄴㅈ',
  'ㄴㅎ',
  'ㄷ',
  'ㄹ',
  'ㄹㄱ',
  'ㄹㅁ',
  'ㄹㅂ',
  'ㄹㅅ',
  'ㄹㅌ',
  'ㄹㅍ',
  'ㄹㅎ',
  'ㅁ',
  'ㅂ',
  'ㅂㅅ',
  'ㅅ',
  'ㅆ',
  'ㅇ',
  'ㅈ',
  'ㅊ',
  'ㅋ',
  'ㅌ',
  'ㅍ',
  'ㅎ',
];

/// 홀로 쓰인 겹자모도 스트림에서는 타이핑 순서로 분해
const Map<String, String> _compoundJamo = {
  'ㄳ': 'ㄱㅅ',
  'ㄵ': 'ㄴㅈ',
  'ㄶ': 'ㄴㅎ',
  'ㄺ': 'ㄹㄱ',
  'ㄻ': 'ㄹㅁ',
  'ㄼ': 'ㄹㅂ',
  'ㄽ': 'ㄹㅅ',
  'ㄾ': 'ㄹㅌ',
  'ㄿ': 'ㄹㅍ',
  'ㅀ': 'ㄹㅎ',
  'ㅄ': 'ㅂㅅ',
  'ㅘ': 'ㅗㅏ',
  'ㅙ': 'ㅗㅐ',
  'ㅚ': 'ㅗㅣ',
  'ㅝ': 'ㅜㅓ',
  'ㅞ': 'ㅜㅔ',
  'ㅟ': 'ㅜㅣ',
  'ㅢ': 'ㅡㅣ',
};

bool _isSyllable(int code) =>
    code >= _syllableBase && code < _syllableBase + _syllableCount;

/// 호환 자모 자음(ㄱ~ㅎ) 여부 — 초성 검색어 판별용
bool _isConsonantJamo(int code) => code >= 0x3131 && code <= 0x314E;

/// 텍스트에 한글 음절이 하나라도 있는지 (검색 엔진이 한글 매칭을 시도할지 판단)
bool containsHangul(String text) =>
    text.codeUnits.any((c) => _isSyllable(c) || _isConsonantJamo(c));

/// 검색어가 초성으로만 이루어졌는지 ('ㄱㅇㅇ' → true, '고ㅇ' → false)
bool isChoseongQuery(String query) =>
    query.isNotEmpty && query.codeUnits.every(_isConsonantJamo);

/// 각 음절을 초성으로 바꾼 문자열 ('고양이' → 'ㄱㅇㅇ', 비한글은 그대로)
String toChoseong(String text) {
  final buffer = StringBuffer();
  for (final code in text.codeUnits) {
    if (_isSyllable(code)) {
      buffer.write(
        _choseong[(code - _syllableBase) ~/ (_jungCount * _jongCount)],
      );
    } else {
      buffer.writeCharCode(code);
    }
  }
  return buffer.toString();
}

/// 음절을 타이핑 순서의 자모 나열로 분해한 문자열
/// ('고양' → 'ㄱㅗㅇㅑㅇ', '값' → 'ㄱㅏㅂㅅ', 비한글은 그대로)
String toJamoStream(String text) {
  final buffer = StringBuffer();
  for (final ch in text.split('')) {
    final code = ch.codeUnitAt(0);
    if (_isSyllable(code)) {
      final offset = code - _syllableBase;
      buffer.write(_choseong[offset ~/ (_jungCount * _jongCount)]);
      buffer.write(
        _jungseong[(offset % (_jungCount * _jongCount)) ~/ _jongCount],
      );
      buffer.write(_jongseong[offset % _jongCount]);
    } else {
      buffer.write(_compoundJamo[ch] ?? ch);
    }
  }
  return buffer.toString();
}

/// 모든 공백 제거 — 매칭 시 띄어쓰기를 무시하기 위한 정규화.
/// ('수영하는 여자'를 'ㅅㅇㅎㄴㅇㅈ'로도, '수영하는여자'로도 찾을 수 있게)
String squashSpaces(String text) => text.replaceAll(RegExp(r'\s'), '');

/// 한글 검색 매칭. 양쪽의 공백은 무시한다.
///
/// - 초성만으로 된 검색어: 대상의 초성 나열에 연속 포함되면 매칭
/// - 그 외(완성 글자, 혼합, 치다 만 입력): 양쪽을 자모 스트림으로 펴서
///   부분 문자열이면 매칭. '고ㅇ'(ㄱㅗㅇ)이 '고양이'(ㄱㅗㅇㅑㅇㅇㅣ)에
///   포함되는 원리로, 타이핑 중간 상태('공' 등)도 자연스럽게 매칭된다.
bool matchesHangul(String target, String query) {
  final q = squashSpaces(query);
  if (q.isEmpty) return false;
  if (isChoseongQuery(q)) {
    return squashSpaces(toChoseong(target)).contains(q);
  }
  return squashSpaces(toJamoStream(target)).contains(toJamoStream(q));
}
