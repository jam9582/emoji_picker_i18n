import 'package:shared_preferences/shared_preferences.dart';

/// 최근 사용 이모지 저장소 인터페이스.
///
/// 피커는 저장 방식을 강제하지 않고 이 인터페이스를 주입받는다.
/// 기본값은 [PrefsRecentEmojiStorage] (shared_preferences 영구 저장)이며,
/// 앱의 DB 등 다른 곳에 저장하려면 이 인터페이스를 구현해 주입하면 된다.
///
/// 이모지 문자열 목록(최신순)만 주고받으며, 이름·피부색 같은 메타데이터는
/// 피커가 데이터에서 다시 찾아 붙인다.
abstract class RecentEmojiStorage {
  /// 저장된 이모지 문자열 목록 (최신순).
  Future<List<String>> load();

  /// 이모지 문자열 목록 저장 (최신순).
  Future<void> save(List<String> emojiChars);
}

/// shared_preferences 기반 영구 저장소 (기본값).
class PrefsRecentEmojiStorage implements RecentEmojiStorage {
  const PrefsRecentEmojiStorage({this.key = 'emoji_picker_i18n_recents'});

  /// shared_preferences 저장 키. 한 앱에서 용도별 최근 목록을 여러 개
  /// 유지하고 싶으면 키를 다르게 지정.
  final String key;

  @override
  Future<List<String>> load() async =>
      (await SharedPreferences.getInstance()).getStringList(key) ?? const [];

  @override
  Future<void> save(List<String> emojiChars) async =>
      (await SharedPreferences.getInstance()).setStringList(key, emojiChars);
}

/// 앱을 끄면 사라지는 메모리 저장소.
///
/// 영구 저장이 필요 없는 화면이나 테스트·데모에 적합.
class MemoryRecentEmojiStorage implements RecentEmojiStorage {
  List<String> _items = [];

  @override
  Future<List<String>> load() async => List.unmodifiable(_items);

  @override
  Future<void> save(List<String> emojiChars) async {
    _items = List.of(emojiChars);
  }
}
