import 'package:flutter_test/flutter_test.dart';

import 'package:emoji_picker_i18n/emoji_picker_i18n.dart';
import 'package:emoji_picker_i18n/locales/bn.dart';
import 'package:emoji_picker_i18n/locales/da.dart';
import 'package:emoji_picker_i18n/locales/de.dart';
import 'package:emoji_picker_i18n/locales/en.dart';
import 'package:emoji_picker_i18n/locales/en_gb.dart';
import 'package:emoji_picker_i18n/locales/es.dart';
import 'package:emoji_picker_i18n/locales/es_mx.dart';
import 'package:emoji_picker_i18n/locales/et.dart';
import 'package:emoji_picker_i18n/locales/fi.dart';
import 'package:emoji_picker_i18n/locales/fr.dart';
import 'package:emoji_picker_i18n/locales/hi.dart';
import 'package:emoji_picker_i18n/locales/hu.dart';
import 'package:emoji_picker_i18n/locales/it.dart';
import 'package:emoji_picker_i18n/locales/ja.dart';
import 'package:emoji_picker_i18n/locales/ko.dart';
import 'package:emoji_picker_i18n/locales/lt.dart';
import 'package:emoji_picker_i18n/locales/ms.dart';
import 'package:emoji_picker_i18n/locales/nb.dart';
import 'package:emoji_picker_i18n/locales/nl.dart';
import 'package:emoji_picker_i18n/locales/pl.dart';
import 'package:emoji_picker_i18n/locales/pt.dart';
import 'package:emoji_picker_i18n/locales/ru.dart';
import 'package:emoji_picker_i18n/locales/sv.dart';
import 'package:emoji_picker_i18n/locales/th.dart';
import 'package:emoji_picker_i18n/locales/uk.dart';
import 'package:emoji_picker_i18n/locales/vi.dart';
import 'package:emoji_picker_i18n/locales/zh.dart';
import 'package:emoji_picker_i18n/locales/zh_hant.dart';

void main() {
  final allLocales = <String, List<String>>{
    'bn': kEmojiLocaleBn,
    'da': kEmojiLocaleDa,
    'de': kEmojiLocaleDe,
    'en': kEmojiLocaleEn,
    'en-gb': kEmojiLocaleEnGb,
    'es': kEmojiLocaleEs,
    'es-mx': kEmojiLocaleEsMx,
    'et': kEmojiLocaleEt,
    'fi': kEmojiLocaleFi,
    'fr': kEmojiLocaleFr,
    'hi': kEmojiLocaleHi,
    'hu': kEmojiLocaleHu,
    'it': kEmojiLocaleIt,
    'ja': kEmojiLocaleJa,
    'ko': kEmojiLocaleKo,
    'lt': kEmojiLocaleLt,
    'ms': kEmojiLocaleMs,
    'nb': kEmojiLocaleNb,
    'nl': kEmojiLocaleNl,
    'pl': kEmojiLocalePl,
    'pt': kEmojiLocalePt,
    'ru': kEmojiLocaleRu,
    'sv': kEmojiLocaleSv,
    'th': kEmojiLocaleTh,
    'uk': kEmojiLocaleUk,
    'vi': kEmojiLocaleVi,
    'zh': kEmojiLocaleZh,
    'zh-hant': kEmojiLocaleZhHant,
  };

  test('28개 언어 전부 공통 데이터와 같은 길이', () {
    expect(allLocales.length, 28);
    for (final entry in allLocales.entries) {
      expect(
        entry.value.length,
        kEmojiCommon.length,
        reason: '${entry.key} 길이 불일치',
      );
      expect(
        entry.value.every((e) => e.isNotEmpty),
        isTrue,
        reason: '${entry.key}에 빈 항목 존재',
      );
    }
  });

  test('대표 언어들에서 고양이 검색이 동작한다', () {
    const catQueries = {
      'ja': 'ネコ', // 일본어 (데이터는 가타카나·한자 표기)
      'th': 'แมว', // 태국어
      'es': 'gato', // 스페인어
      'de': 'katze', // 독일어
      'ru': 'кош', // 러시아어 (кошка 앞부분)
      'vi': 'mèo', // 베트남어
    };
    const catEmojis = {'🐈️', '🐱', '🐈‍⬛'};

    for (final entry in catQueries.entries) {
      final search = EmojiSearch(
        common: kEmojiCommon,
        locales: [allLocales[entry.key]!],
      );
      final hits = search.search(entry.value).map((e) => e.char);
      expect(
        hits.any(catEmojis.contains),
        isTrue,
        reason: '${entry.key}에서 "${entry.value}" 검색 실패',
      );
    }
  });

  // 각 언어 데이터가 실제 현지어로 채워졌는지(영어 폴백이 아닌지) 검증한다.
  // 대표 이모지 3종의 태그가 영어 태그의 부분집합이면 = 고유 키워드가 하나도
  // 없다는 뜻이므로 폴백을 의심한다. (en/en_gb는 원래 영어라 제외)
  test('28개 언어 모두 영어 폴백 없이 현지어로 채워짐', () {
    const probes = ['🐱', '🐶', '❤️']; // 고양이·개·하트
    final en = EmojiSearch(common: kEmojiCommon, locales: [kEmojiLocaleEn]);
    final enTags = {for (final c in probes) c: en.findByChar(c)!.tags.toSet()};

    for (final entry in allLocales.entries) {
      final s = EmojiSearch(common: kEmojiCommon, locales: [entry.value]);
      for (final c in probes) {
        final e = s.findByChar(c);
        expect(e, isNotNull, reason: '${entry.key}에 $c 없음');
        expect(e!.tags, isNotEmpty, reason: '${entry.key} $c 태그 비어 있음');
        if (entry.key == 'en' || entry.key == 'en-gb') continue;
        // 영어 태그만으로 이뤄져 있지 않아야 한다(고유어 최소 1개)
        expect(
          e.tags.toSet().difference(enTags[c]!),
          isNotEmpty,
          reason: '${entry.key} $c 태그가 영어와 동일 (폴백 의심)',
        );
      }
    }
  });

  test('카테고리 이름도 언어별로 생성됨', () {
    expect(kEmojiGroupNamesJa.length, 10);
    expect(kEmojiGroupNamesTh.length, 10);
    expect(kEmojiGroupNamesKo[3], '동물과 자연');
  });
}
