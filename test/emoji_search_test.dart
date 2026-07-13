import 'package:flutter_test/flutter_test.dart';

import 'package:emoji_picker_i18n/emoji_picker_i18n.dart';
import 'package:emoji_picker_i18n/locales/en.dart';
import 'package:emoji_picker_i18n/locales/ko.dart';

void main() {
  // 한국어 대표 + 영어 동시 검색 구성 (색인은 1회 구축 후 공유)
  final search = EmojiSearch(
    common: kEmojiCommon,
    locales: [kEmojiLocaleKo, kEmojiLocaleEn],
  );

  group('포함 검색', () {
    test('한국어: 고양이', () {
      final chars = search.search('고양이').map((e) => e.char).toList();
      expect(chars, contains('🐱'));
      expect(chars.first, '🐈️', reason: '이름이 정확히 "고양이"인 것이 1순위');
    });

    test('영어도 동시에 검색됨: cat', () {
      expect(search.search('cat').map((e) => e.char), contains('🐱'));
    });

    test('대소문자 무시: CAT', () {
      expect(search.search('CAT').map((e) => e.char), contains('🐱'));
    });

    test('조합 이모지: 수영하는 여자', () {
      expect(search.search('수영하는 여자').map((e) => e.char), contains('🏊‍♀️'));
    });
  });

  group('한글 특화 검색', () {
    test('초성: ㄱㅇㅇ', () {
      expect(search.search('ㄱㅇㅇ').map((e) => e.char), contains('🐱'));
    });

    test('완성+초성 혼합: 고ㅇ', () {
      expect(search.search('고ㅇ').map((e) => e.char), contains('🐱'));
    });

    test('치다 만 입력: 고양ㅇ', () {
      expect(search.search('고양ㅇ').map((e) => e.char), contains('🐱'));
    });

    test('띄어쓰기 있는 키워드의 초성 검색 (공백 무시)', () {
      // '수영하는 여자' — 붙여 치든 띄어 치든 검색돼야 함
      expect(search.search('ㅅㅇㅎㄴㅇㅈ').map((e) => e.char), contains('🏊‍♀️'));
      expect(search.search('ㅅㅇㅎㄴ ㅇㅈ').map((e) => e.char), contains('🏊‍♀️'));
      expect(search.search('수영하는여자').map((e) => e.char), contains('🏊‍♀️'));
    });
  });

  group('검색 결과 규칙', () {
    test('빈 검색어는 빈 결과', () {
      expect(search.search(''), isEmpty);
      expect(search.search('   '), isEmpty);
    });

    test('없는 검색어는 빈 결과', () {
      expect(search.search('쀍쀍쀍'), isEmpty);
    });

    test('limit 적용', () {
      expect(search.search('동물', limit: 5).length, 5);
    });

    test('정확 일치가 접두·포함 일치보다 앞', () {
      final results = search.search('고양이');
      // '고양이'(정확) → '고양이 얼굴' 등(접두) → '검은 고양이' 등(포함)
      expect(results.first.label, '고양이');
    });
  });

  group('표기 정규화', () {
    test('FE0F 유무가 달라도 같은 이모지로 판정', () {
      expect(sameEmoji('🐈️', '🐈'), isTrue);
      expect(sameEmoji('🐱', '🐶'), isFalse);
    });

    test('외부 저장값으로 역조회: 지정자 없는 🐈도 찾음', () {
      final emoji = search.findByChar('🐈'); // 데이터에는 🐈+FE0F로 수록
      expect(emoji, isNotNull);
      expect(emoji!.label, '고양이');
    });

    test('피부색 변형 역조회', () {
      final wave = search.findByChar('👋');
      expect(wave!.skins.length, 5);
    });
  });

  group('전체 목록 (피커 그리드용)', () {
    test('표준 순서로 1906개 제공', () {
      expect(search.emojis.length, 1906);
      expect(search.emojis.first.char, '😀', reason: '유니코드 표준 순서 1번');
    });
  });
}
