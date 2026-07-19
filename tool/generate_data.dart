// 데이터 생성 파이프라인
//
// tool/cache/<locale>.json (emojibase-data compact 형식)을 읽어
// 라이브러리용 Dart 데이터 파일을 생성한다.
//
//   - lib/src/data/emoji_common.dart      : 언어 무관 공통 데이터 1벌
//   - lib/src/data/emoji_locale_<xx>.dart : 언어별 이름·키워드
//
// 추가로 tool/cache/data_en.json (emojibase-data 전체판 data.json)이 필요하다.
// 이모지별 유니코드 버전(구형 기기 필터용)이 compact에는 없어서 여기서 병합한다.
// 버전은 언어 무관이므로 en 한 벌이면 충분하다:
//   curl -o tool/cache/data_en.json \
//     https://cdn.jsdelivr.net/npm/emojibase-data@16.0.3/en/data.json
//
// 사용법:
//   dart run tool/generate_data.dart          # cache의 모든 언어 처리
//   dart run tool/generate_data.dart ko en    # 지정 언어만 처리
//
// 형식 규칙:
//   공통:   'unicode|group|version' 또는 'unicode|group|version|skin1,skin2,...'
//           (피부색 변형의 버전이 기본형과 다르면 'skin@version'으로 표기 —
//            예: 🤝는 3인데 🤝🏻는 14에 추가됨)
//   언어별: 'label|tag1|tag2|...'  (공통 데이터와 같은 인덱스 순서)
//
// group 2(피부색 등 부품)와 group 없는 항목은 피커에 표시할 수 없으므로 제외.

import 'dart:convert';
import 'dart:io';

const cacheDir = 'tool/cache';
const outDir = 'lib/src/data';
const componentGroup = 2;

void main(List<String> args) {
  final locales = args.isNotEmpty
      ? args
      : Directory(cacheDir)
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .map((f) => f.uri.pathSegments.last.replaceAll('.json', ''))
          // messages_*(카테고리 이름)·data_*(버전 병합용 전체판)는 언어가 아님
          .where((name) =>
              !name.startsWith('messages_') && !name.startsWith('data_'))
          .toList()
    ..sort();

  if (locales.isEmpty) {
    stderr.writeln('tool/cache 에 emojibase compact json이 없습니다.');
    exit(1);
  }

  // 공통 데이터는 en 기준으로 생성 (없으면 첫 번째 언어 기준)
  final baseLocale = locales.contains('en') ? 'en' : locales.first;
  final baseEntries = _loadPickerEntries(baseLocale);
  final hexOrder = [for (final e in baseEntries) e['hexcode'] as String];

  Directory(outDir).createSync(recursive: true);
  _writeCommon(baseEntries, _loadVersions());

  for (final locale in locales) {
    _writeLocale(locale, hexOrder);
  }

  stdout.writeln(
      '완료: 공통 ${baseEntries.length}개 + 언어 ${locales.length}종 (${locales.join(', ')})');
}

/// 피커 대상 이모지만 추려 표시 순서(order)로 정렬해 반환.
List<Map<String, dynamic>> _loadPickerEntries(String locale) {
  final file = File('$cacheDir/$locale.json');
  if (!file.existsSync()) {
    stderr.writeln('없음: ${file.path}');
    exit(1);
  }
  final all = (jsonDecode(file.readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();
  final picker = all
      .where((e) => e['group'] != null && e['group'] != componentGroup)
      .toList()
    ..sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
  return picker;
}

/// tool/cache/data_en.json에서 hexcode → 유니코드 버전 맵을 만든다.
/// 피부색 변형의 hexcode도 함께 담는다.
Map<String, num> _loadVersions() {
  final file = File('$cacheDir/data_en.json');
  if (!file.existsSync()) {
    stderr.writeln('없음: ${file.path} — 파일 상단 주석의 curl 명령으로 받을 것');
    exit(1);
  }
  final all = (jsonDecode(file.readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();
  final versions = <String, num>{};
  for (final e in all) {
    versions[e['hexcode'] as String] = e['version'] as num;
    for (final s in (e['skins'] as List?) ?? const []) {
      versions[(s as Map)['hexcode'] as String] = s['version'] as num;
    }
  }
  return versions;
}

/// 0.6 → '0.6', 14 → '14' (뒤의 .0은 생략해 파일 크기 절약)
String _fmtVersion(num v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

void _writeCommon(List<Map<String, dynamic>> entries, Map<String, num> versions) {
  num versionOf(String hexcode) {
    final v = versions[hexcode];
    if (v == null) {
      throw StateError('data_en.json에 버전 정보 없음: $hexcode');
    }
    return v;
  }

  final lines = entries.map((e) {
    final unicode = e['unicode'] as String;
    final group = e['group'] as int;
    final version = versionOf(e['hexcode'] as String);
    // 변형의 버전이 기본형과 다르면 '@버전'을 붙인다 (🤝=3, 🤝🏻=14)
    final skins = (e['skins'] as List?)?.map((s) {
      final skinChar = (s as Map)['unicode'] as String;
      final skinVersion = versionOf(s['hexcode'] as String);
      return skinVersion == version
          ? skinChar
          : '$skinChar@${_fmtVersion(skinVersion)}';
    }).join(',');
    final base = '$unicode|$group|${_fmtVersion(version)}';
    final value = skins == null ? base : '$base|$skins';
    return "  '${_escape(value)}',";
  }).join('\n');

  File('$outDir/emoji_common.dart').writeAsStringSync('''
// GENERATED FILE - tool/generate_data.dart 로 생성됨. 직접 수정 금지.
//
// 형식: 'unicode|group|version' 또는 'unicode|group|version|skin1,skin2@ver,...'
// (피부색 변형의 @ver 은 기본형과 버전이 다를 때만 붙음)

const List<String> kEmojiCommon = [
$lines
];
''');
}

void _writeLocale(String locale, List<String> hexOrder) {
  final entries = _loadPickerEntries(locale);
  final byHex = {for (final e in entries) e['hexcode'] as String: e};

  final lines = hexOrder.map((hex) {
    final e = byHex[hex];
    if (e == null) {
      stderr.writeln('경고: $locale 에 $hex 항목 없음 - 빈 값으로 채움');
      return "  '',";
    }
    final label = e['label'] as String;
    final tags = (e['tags'] as List?)?.cast<String>() ?? const [];
    for (final part in [label, ...tags]) {
      if (part.contains('|')) {
        throw StateError("구분자 '|' 가 데이터에 포함됨: $locale $hex '$part'");
      }
    }
    return "  '${_escape([label, ...tags].join('|'))}',";
  }).join('\n');

  final varName = 'kEmojiLocale${_camelCase(locale)}';
  final fileName = _fileSafe(locale);
  File('$outDir/emoji_locale_$fileName.dart').writeAsStringSync('''
// GENERATED FILE - tool/generate_data.dart 로 생성됨. 직접 수정 금지.
//
// 형식: 'label|tag1|tag2|...' (emoji_common.dart 와 같은 인덱스 순서)

const List<String> $varName = [
$lines
];
${_groupNamesConst(locale)}''');

  // 사용자용 공개 import 경로: package:emoji_picker_i18n/locales/<locale>.dart
  Directory('lib/locales').createSync(recursive: true);
  File('lib/locales/$fileName.dart').writeAsStringSync('''
// GENERATED FILE - tool/generate_data.dart 로 생성됨. 직접 수정 금지.

export '../src/data/emoji_locale_$fileName.dart';
''');
}

/// 카테고리(그룹) 이름 상수 코드 생성.
/// `tool/cache/messages_<locale>.json` (emojibase messages 형식)이 있으면
/// 그룹 번호 순서의 이름 목록을 만들고, 없으면 생략한다.
String _groupNamesConst(String locale) {
  final file = File('$cacheDir/messages_$locale.json');
  if (!file.existsSync()) {
    stderr.writeln('안내: messages_$locale.json 없음 - 카테고리 이름 생략');
    return '';
  }
  final groups = ((jsonDecode(file.readAsStringSync())
          as Map<String, dynamic>)['groups'] as List)
      .cast<Map<String, dynamic>>()
    ..sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
  final names =
      groups.map((g) => "  '${_escape(g['message'] as String)}',").join('\n');
  return '''

/// 카테고리(그룹) 이름 — 인덱스가 그룹 번호와 일치
const List<String> kEmojiGroupNames${_camelCase(locale)} = [
$names
];
''';
}

String _escape(String s) =>
    s.replaceAll(r'\', r'\\').replaceAll("'", r"\'").replaceAll(r'$', r'\$');

/// 'en-gb' → 'EnGb' (Dart 상수 이름용)
String _camelCase(String locale) => locale
    .split('-')
    .map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1))
    .join();

/// 'en-gb' → 'en_gb' (Dart 파일명 규칙용)
String _fileSafe(String locale) => locale.replaceAll('-', '_');
