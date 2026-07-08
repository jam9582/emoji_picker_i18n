import '../emoji.dart';
import 'hangul.dart';
import 'normalize.dart';

/// 다국어 이모지 검색 엔진 (기획서 5-1절).
///
/// - 포함 검색: 키워드에 검색어가 포함되면 매칭
/// - 한글 검색: 초성('ㄱㅇㅇ')·혼합('고ㅇ')·치다 만 입력('고양ㅇ') 지원
/// - 순위: 정확 일치 > 접두 일치 > 포함 순이며, 같은 단계에서는
///   이름(label) 일치가 태그 일치보다 앞선다 (같은 순위면 이모지 표준 순서)
///
/// 여러 언어를 넘기면 모든 언어에서 동시에 검색된다.
/// 색인은 생성 시 1회 구축되며 이후 검색은 추가 비용이 없다.
class EmojiSearch {
  /// [common]은 kEmojiCommon, [locales]는 kEmojiLocaleKo 등 언어 데이터 목록.
  /// 첫 번째 언어가 [Emoji.label]의 대표 언어가 된다.
  EmojiSearch({
    required List<String> common,
    required List<List<String>> locales,
  })  : assert(locales.isNotEmpty, '언어 데이터가 최소 1개 필요'),
        emojis = parseEmojiData(common, locales.first) {
    _entries = List.generate(emojis.length, (i) {
      final keywords = <_Keyword>[];
      for (final locale in locales) {
        final parts = locale[i].split('|');
        for (var p = 0; p < parts.length; p++) {
          keywords.add(_Keyword(parts[p].toLowerCase(), isLabel: p == 0));
        }
      }
      return keywords;
    });
    _charIndex = {
      for (var i = 0; i < emojis.length; i++)
        normalizeEmoji(emojis[i].char): emojis[i],
    };
  }

  /// 표준 순서로 정렬된 전체 이모지 (피커 그리드 표시용).
  final List<Emoji> emojis;

  late final List<List<_Keyword>> _entries;
  late final Map<String, Emoji> _charIndex;

  /// [query]에 매칭되는 이모지를 순위순으로 반환한다.
  List<Emoji> search(String query, {int limit = 60}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final jamoQuery = containsHangul(q) && !isChoseongQuery(q)
        ? toJamoStream(q)
        : null;

    final scored = <(int score, int index)>[];
    for (var i = 0; i < _entries.length; i++) {
      int? best;
      for (final keyword in _entries[i]) {
        final s = keyword.score(q, jamoQuery);
        if (s != null && (best == null || s < best)) {
          best = s;
          if (best == 0) break;
        }
      }
      if (best != null) scored.add((best, i));
    }

    scored.sort((a, b) {
      final byScore = a.$1.compareTo(b.$1);
      return byScore != 0 ? byScore : a.$2.compareTo(b.$2);
    });

    return [
      for (final (_, i) in scored.take(limit)) emojis[i],
    ];
  }

  /// 외부 출처의 이모지 문자열로 데이터를 역조회한다 (표기 차이 무시).
  ///
  /// 앱에 저장된 선택값 강조, 피부색 변형 조회 등에 사용 (기획서 5-1절
  /// 적용 지점 ⓑ·ⓒ). 데이터에 없는 이모지면 null.
  Emoji? findByChar(String emojiChar) => _charIndex[normalizeEmoji(emojiChar)];
}

/// 키워드 하나와, 한글일 경우의 초성·자모 변환 캐시.
class _Keyword {
  _Keyword(this.text, {required this.isLabel})
      : choseong = containsHangul(text) ? toChoseong(text) : null,
        jamo = containsHangul(text) ? toJamoStream(text) : null;

  final String text;

  /// 이름(label)인지 태그인지 — 같은 일치 단계에서 이름이 태그보다 앞선다
  final bool isLabel;

  final String? choseong;
  final String? jamo;

  /// 매칭 점수 (낮을수록 상위):
  ///   정확(0,1) > 접두(2,3) > 포함(4,5), 짝수=이름·홀수=태그. 불일치면 null.
  int? score(String query, String? jamoQuery) {
    int? best = _rank(text, query);

    if (choseong != null && isChoseongQuery(query)) {
      best = _min(best, _rank(choseong!, query));
    }
    if (jamo != null && jamoQuery != null) {
      best = _min(best, _rank(jamo!, jamoQuery));
    }
    return best;
  }

  int? _rank(String keyword, String query) {
    final tagPenalty = isLabel ? 0 : 1;
    if (keyword == query) return 0 + tagPenalty;
    if (keyword.startsWith(query)) return 2 + tagPenalty;
    if (keyword.contains(query)) return 4 + tagPenalty;
    return null;
  }

  static int? _min(int? a, int? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a < b ? a : b;
  }
}
