/// 다국어 검색을 지원하는 Flutter 이모지 피커.
///
/// 언어 데이터는 앱 용량 최적화(트리 셰이킹)를 위해 자동으로 포함되지 않는다.
/// 사용할 언어의 데이터 파일을 직접 import 해서 넘길 것:
///
/// ```dart
/// import 'package:emoji_picker_i18n/emoji_picker_i18n.dart';
/// import 'package:emoji_picker_i18n/locales/ko.dart';
/// import 'package:emoji_picker_i18n/locales/en.dart';
///
/// final search = EmojiSearch(
///   common: kEmojiCommon,
///   locales: [kEmojiLocaleKo, kEmojiLocaleEn],
/// );
/// search.search('고양이'); // ㄱㅇㅇ, 고ㅇ 도 가능
/// ```
library;

export 'src/data/emoji_common.dart';
export 'src/emoji.dart';
export 'src/recents/recent_emoji_storage.dart';
export 'src/search/emoji_search.dart';
export 'src/search/normalize.dart';
export 'src/support/emoji_version_detect.dart';
export 'src/ui/emoji_grid.dart';
export 'src/ui/emoji_picker_config.dart';
export 'src/ui/emoji_picker_i18n.dart';
export 'src/ui/emoji_picker_theme.dart';
