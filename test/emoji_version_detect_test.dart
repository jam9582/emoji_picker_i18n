import 'package:flutter_test/flutter_test.dart';

import 'package:emoji_picker_i18n/emoji_picker_i18n.dart';
import 'package:emoji_picker_i18n/locales/ko.dart';

void main() {
  group('detectMaxEmojiVersion (판정 주입)', () {
    /// [supported]에 있는 이모지만 지원하는 가짜 기기를 흉내낸다
    Future<bool> Function(String, {required bool isSequence}) fakeDevice(
      Set<String> supported,
    ) =>
        (emoji, {required bool isSequence}) async => supported.contains(emoji);

    test('최신 이모지까지 되는 기기는 최신 버전을 반환', () async {
      final version = await detectMaxEmojiVersion(
        isSupported: fakeDevice({'🫩', '🙂‍↔️', '🫨', '🫠', '🥲', '😀'}),
      );
      expect(version, 16);
    });

    test('구형 기기: 처음으로 그려지는 버전에서 멈춘다 (Android 12 = 13.1 가정)', () async {
      final version = await detectMaxEmojiVersion(
        isSupported: fakeDevice({'😶‍🌫️', '🥲', '🥱', '🥰', '🤩', '🤣', '😀'}),
      );
      expect(version, 13.1);
    });

    test('중간 버전만 되는 이상한 기기도 첫 성공에서 판정', () async {
      final version = await detectMaxEmojiVersion(
        isSupported: fakeDevice({'🥰', '😀'}),
      );
      expect(version, 11);
    });

    test('기준 이모지(😀)조차 안 그려지면 null (감지 포기 → 필터 없음)', () async {
      final version = await detectMaxEmojiVersion(isSupported: fakeDevice({}));
      expect(version, isNull);
    });

    test('판정 함수가 던져도 크래시 없이 null', () async {
      final version = await detectMaxEmojiVersion(
        isSupported: (_, {required isSequence}) async =>
            throw StateError('render fail'),
      );
      expect(version, isNull);
    });

    test('감지 결과가 maxEmojiVersion으로 그대로 연결된다', () async {
      final version = await detectMaxEmojiVersion(
        isSupported: fakeDevice({'🥲', '😀'}),
      );
      final search = EmojiSearch(
        common: kEmojiCommon,
        locales: [kEmojiLocaleKo],
        maxEmojiVersion: version,
      );
      expect(search.emojis.any((e) => e.char == '🥲'), isTrue);
      expect(search.emojis.any((e) => e.char == '🫠'), isFalse);
    });
  });

  group('detectMaxEmojiVersion (실제 렌더링)', () {
    // 테스트 환경은 실제 이모지 폰트가 없어(Ahem 폰트) 결과가 환경마다 다르다.
    // 크래시 없이 null 또는 유효한 버전을 내는지만 확인한다.
    test('테스트 환경에서도 안전하게 동작', () async {
      final version = await detectMaxEmojiVersion();
      expect(
        version == null || (version >= 1 && version <= 16),
        isTrue,
        reason: '버전이면 프로브 범위 안이어야 함 (실제값: $version)',
      );
    });
  });
}
