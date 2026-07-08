import 'package:flutter_test/flutter_test.dart';

import 'package:emoji_picker_i18n/src/search/hangul.dart';

void main() {
  group('분해 유틸', () {
    test('초성 추출', () {
      expect(toChoseong('고양이'), 'ㄱㅇㅇ');
      expect(toChoseong('수영하는 여자'), 'ㅅㅇㅎㄴ ㅇㅈ');
      expect(toChoseong('cat고양이'), 'catㄱㅇㅇ');
    });

    test('자모 스트림 분해', () {
      expect(toJamoStream('고양'), 'ㄱㅗㅇㅑㅇ');
      expect(toJamoStream('값'), 'ㄱㅏㅂㅅ'); // 겹받침 분해
      expect(toJamoStream('화'), 'ㅎㅗㅏ'); // 겹모음 분해
      expect(toJamoStream('고ㅇ'), 'ㄱㅗㅇ'); // 낱자모는 그대로 이어붙임
    });

    test('검색어 유형 판별', () {
      expect(isChoseongQuery('ㄱㅇㅇ'), isTrue);
      expect(isChoseongQuery('고ㅇ'), isFalse);
      expect(isChoseongQuery('ㅏ'), isFalse); // 모음은 초성 검색 아님
      expect(containsHangul('고양이'), isTrue);
      expect(containsHangul('cat'), isFalse);
    });
  });

  group('한글 매칭 (기획서 5-1절 시나리오)', () {
    test('초성만: ㄱㅇㅇ → 고양이', () {
      expect(matchesHangul('고양이', 'ㄱㅇㅇ'), isTrue);
      expect(matchesHangul('새끼 고양이', 'ㄱㅇㅇ'), isTrue); // 중간 시작
      expect(matchesHangul('고양이', 'ㄴㅇㅇ'), isFalse);
    });

    test('완성+초성 혼합: 고ㅇ → 고양이', () {
      expect(matchesHangul('고양이', '고ㅇ'), isTrue);
      expect(matchesHangul('공주', '고ㅇ'), isTrue); // 공주도 후보로 나오는 게 자연스러움
      expect(matchesHangul('곰돌이', '고ㅇ'), isFalse); // ㅁ 받침이라 불일치
    });

    test('치다 만 입력: 고양ㅇ → 고양이', () {
      expect(matchesHangul('고양이', '고양ㅇ'), isTrue);
      expect(matchesHangul('고양이', '고야'), isTrue); // 양의 중간 단계
      expect(matchesHangul('고양이', '공'), isTrue); // 타이핑 중간 상태(ㄱㅗㅇ)
      expect(matchesHangul('고양이', '고얌'), isFalse);
    });

    test('완성 글자 그대로도 매칭', () {
      expect(matchesHangul('고양이', '고양이'), isTrue);
      expect(matchesHangul('고양이', '양이'), isTrue);
      expect(matchesHangul('고양이', '강아지'), isFalse);
    });

    test('빈 검색어는 매칭 안 함', () {
      expect(matchesHangul('고양이', ''), isFalse);
    });
  });
}
