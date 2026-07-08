import 'package:flutter_test/flutter_test.dart';

import 'package:emoji_picker_i18n/src/data/emoji_common.dart';
import 'package:emoji_picker_i18n/src/data/emoji_locale_en.dart';
import 'package:emoji_picker_i18n/src/data/emoji_locale_ko.dart';

/// 키워드에 [query]가 포함된 이모지 문자 목록을 반환하는 최소 검색.
/// (엔진 구현 전, 데이터 자체가 검색 가능한지 검증하는 용도)
List<String> rawSearch(List<String> localeData, String query) {
  final result = <String>[];
  for (var i = 0; i < localeData.length; i++) {
    if (localeData[i].contains(query)) {
      result.add(kEmojiCommon[i].split('|').first);
    }
  }
  return result;
}

void main() {
  test('공통 데이터와 언어 데이터의 인덱스가 정렬되어 있다', () {
    expect(kEmojiCommon.length, 1906);
    expect(kEmojiLocaleKo.length, kEmojiCommon.length);
    expect(kEmojiLocaleEn.length, kEmojiCommon.length);
  });

  test('한국어로 고양이를 검색하면 고양이 이모지가 나온다', () {
    final hits = rawSearch(kEmojiLocaleKo, '고양이');
    expect(hits, contains('🐱'));
    // 🐈는 이모지 표시 지정자(U+FE0F)가 붙은 형태로 수록됨
    expect(hits, contains('🐈️'));
  });

  test('영어로 cat을 검색하면 고양이 이모지가 나온다', () {
    final hits = rawSearch(kEmojiLocaleEn, 'cat');
    expect(hits, contains('🐱'));
  });

  test('조합(ZWJ) 이모지도 완성된 한국어 번역을 가진다', () {
    // 기존 라이브러리가 실패하던 케이스 (기획서 3-1절 문제점 6번)
    final hits = rawSearch(kEmojiLocaleKo, '수영하는 여자');
    expect(hits, contains('🏊‍♀️'));
  });

  test('피부색 변형이 공통 데이터에 붙어 있다', () {
    final wave = kEmojiCommon.firstWhere((e) => e.startsWith('👋'));
    final parts = wave.split('|');
    expect(parts.length, 3, reason: '스킨 목록이 있어야 함');
    expect(parts[2].split(',').length, 5, reason: '피부색 5종');
  });
}
