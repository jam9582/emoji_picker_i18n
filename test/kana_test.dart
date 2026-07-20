import 'package:flutter_test/flutter_test.dart';

import 'package:emoji_picker_i18n/emoji_picker_i18n.dart';
import 'package:emoji_picker_i18n/locales/ja.dart';
import 'package:emoji_picker_i18n/src/search/kana.dart';

void main() {
  group('가나 정규화', () {
    test('히라가나 → 가타카나 변환', () {
      expect(normalizeKana('ねこ'), 'ネコ');
      expect(normalizeKana('がっこう'), 'ガッコウ'); // 탁음·촉음 포함
      expect(normalizeKana('ゔ'), 'ヴ');
    });

    test('가나가 아닌 글자는 그대로', () {
      expect(normalizeKana('ネコ'), 'ネコ'); // 이미 가타카나
      expect(normalizeKana('猫'), '猫'); // 한자
      expect(normalizeKana('고양이 cat'), '고양이 cat');
    });
  });

  group('일본어 검색 (입력기 히라가나 대응)', () {
    final search = EmojiSearch(common: kEmojiCommon, locales: [kEmojiLocaleJa]);
    const catEmojis = {'🐈️', '🐱', '🐈‍⬛'};

    test('히라가나로 쳐도 가타카나 키워드가 검색된다', () {
      // 데이터는 ネコ(가타카나)지만 입력기는 ねこ(히라가나)를 먼저 내놓음
      final hits = search.search('ねこ').map((e) => e.char);
      expect(hits.any(catEmojis.contains), isTrue);
    });

    test('가타카나 검색은 그대로 동작', () {
      final hits = search.search('ネコ').map((e) => e.char);
      expect(hits.any(catEmojis.contains), isTrue);
    });

    test('한자 검색도 그대로 동작', () {
      final hits = search.search('猫').map((e) => e.char);
      expect(hits.any(catEmojis.contains), isTrue);
    });
  });
}
