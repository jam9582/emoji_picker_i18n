import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// 이 기기가 어느 유니코드 이모지 버전까지 그릴 수 있는지 실측으로 알아낸다.
///
/// 버전별 대표 이모지를 최신부터 하나씩 몰래 그려보고(화면에 표시되지 않음),
/// 처음으로 제대로 그려지는 버전을 반환한다. 결과를
/// [EmojiSearch.maxEmojiVersion]에 넘기면 구형 기기에서 □(두부)로 보이는
/// 이모지가 목록에서 사라진다.
///
/// ```dart
/// final maxVersion = await detectMaxEmojiVersion();
/// final search = EmojiSearch(
///   common: kEmojiCommon,
///   locales: [kEmojiLocaleKo],
///   maxEmojiVersion: maxVersion,
/// );
/// ```
///
/// 감지에 실패하면 null을 반환한다 — 이때는 필터 없이 전부 표시하는 것이
/// 안전하다 (멀쩡한 이모지를 숨기는 것보다 □ 몇 개가 낫다).
/// 비용은 프로브 몇 개를 40px 이미지로 그리는 정도라 수 ms 수준이지만,
/// 결과는 기기에서 변하지 않으므로 앱에서 한 번만 호출해 재사용을 권장.
///
/// 판정 방법 (웹 피커들의 검증된 관행을 Dart로 이식):
/// - 색 검사: 같은 이모지를 검정/흰색 글자색으로 두 번 그려 픽셀 비교.
///   컬러 이모지는 글자색을 무시하므로 두 결과가 같고, □는 글자색으로
///   그려지므로 달라진다
/// - 폭 검사(조합 이모지): 지원 안 되는 조합(🙂‍↔️ 등)은 구성 요소로 쪼개져
///   기준 이모지보다 훨씬 넓게 그려진다
Future<double?> detectMaxEmojiVersion({
  @visibleForTesting
  Future<bool> Function(String emoji, {required bool isSequence})? isSupported,
}) async {
  final check = isSupported ?? _isRenderedProperly;
  try {
    for (final probe in _probes) {
      if (await check(probe.char, isSequence: probe.isSequence)) {
        return probe.version;
      }
    }
  } catch (_) {
    // 렌더링 API를 못 쓰는 환경(일부 테스트 등)에서는 감지 포기
  }
  return null;
}

/// 버전별 대표 이모지 (최신 → 과거).
///
/// 단일 코드포인트를 우선 선정하고, 그 버전에 단일 문자가 없으면(12.1 등
/// 조합만 추가된 버전) 조합 이모지를 쓰되 폭 검사를 함께 적용한다.
/// 1.0(😀)까지 전부 실패하면 감지 자체가 무의미한 환경으로 보고 null.
const _probes = [
  _Probe(16, '🫩'), // 눈 밑 처진 얼굴
  _Probe(15.1, '🙂‍↔️', isSequence: true), // 도리도리
  _Probe(15, '🫨'), // 떨리는 얼굴
  _Probe(14, '🫠'), // 녹는 얼굴
  _Probe(13.1, '😶‍🌫️', isSequence: true), // 구름 낀 얼굴
  _Probe(13, '🥲'), // 눈물 머금은 미소
  _Probe(12.1, '🧑‍🦰', isSequence: true), // 빨간 머리 사람
  _Probe(12, '🥱'), // 하품
  _Probe(11, '🥰'), // 하트 미소
  _Probe(5, '🤩'), // 별 눈
  _Probe(3, '🤣'), // 데굴데굴
  _Probe(1, '😀'),
];

class _Probe {
  const _Probe(this.version, this.char, {this.isSequence = false});

  final double version;
  final String char;

  /// ZWJ 조합 여부 — 쪼개져 그려지는 경우를 폭 검사로 잡아야 한다
  final bool isSequence;
}

const double _fontSize = 24;
const int _canvasSize = 40;

/// 기본 판정: (조합이면) 폭 검사 + 색 검사.
Future<bool> _isRenderedProperly(
  String emoji, {
  required bool isSequence,
}) async {
  if (isSequence) {
    // 기준(😀) 폭의 1.8배 이상이면 구성 요소로 쪼개진 것
    final baseline = _measureWidth('😀');
    if (baseline <= 0 || _measureWidth(emoji) > baseline * 1.8) {
      return false;
    }
  }

  final black = await _renderPixels(emoji, const ui.Color(0xFF000000));
  final white = await _renderPixels(emoji, const ui.Color(0xFFFFFFFF));
  if (black == null || white == null) return false;

  // 아무것도 안 그려졌으면(전부 투명) 미지원
  var hasInk = false;
  for (var i = 3; i < black.length; i += 4) {
    if (black[i] != 0) {
      hasInk = true;
      break;
    }
  }
  if (!hasInk) return false;

  // 글자색을 바꿔도 같은 픽셀 = 컬러 글리프. 달라지면 □(글자색으로 그려짐)
  if (black.length != white.length) return false;
  for (var i = 0; i < black.length; i++) {
    if (black[i] != white[i]) return false;
  }
  return true;
}

double _measureWidth(String text) {
  final paragraph = _layout(text, const ui.Color(0xFF000000));
  return paragraph.maxIntrinsicWidth;
}

ui.Paragraph _layout(String text, ui.Color color) {
  final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: _fontSize))
    ..pushStyle(ui.TextStyle(color: color, fontSize: _fontSize))
    ..addText(text);
  return builder.build()
    ..layout(const ui.ParagraphConstraints(width: double.infinity));
}

/// [emoji]를 [color] 글자색으로 그린 40×40 RGBA 픽셀. 실패 시 null.
Future<Uint8List?> _renderPixels(String emoji, ui.Color color) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawParagraph(_layout(emoji, color), ui.Offset.zero);
  final image =
      await recorder.endRecording().toImage(_canvasSize, _canvasSize);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return data?.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
