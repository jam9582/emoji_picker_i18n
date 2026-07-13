/// 최근 사용 이모지 저장소 인터페이스.
///
/// 피커는 저장 방식(shared_preferences, 파일, DB, 서버...)을 강제하지 않고
/// 이 인터페이스를 주입받는다. 이모지 문자열 목록(최신순)만 주고받으며,
/// 이름·피부색 같은 메타데이터는 피커가 데이터에서 다시 찾아 붙인다.
///
/// shared_preferences 를 쓰는 앱이라면 이 정도로 충분하다:
///
/// ```dart
/// class PrefsRecentStorage implements RecentEmojiStorage {
///   @override
///   Future<List<String>> load() async =>
///       (await SharedPreferences.getInstance()).getStringList('recents') ?? [];
///
///   @override
///   Future<void> save(List<String> emojiChars) async =>
///       (await SharedPreferences.getInstance())
///           .setStringList('recents', emojiChars);
/// }
/// ```
abstract class RecentEmojiStorage {
  /// 저장된 이모지 문자열 목록 (최신순).
  Future<List<String>> load();

  /// 이모지 문자열 목록 저장 (최신순).
  Future<void> save(List<String> emojiChars);
}

/// 앱을 끄면 사라지는 메모리 저장소.
///
/// 저장소를 주입하지 않았을 때의 기본값. 세션 내에서는 정상 동작하므로
/// 데모·테스트에 적합하고, 영구 저장이 필요하면 [RecentEmojiStorage]를
/// 직접 구현해 주입할 것.
class MemoryRecentEmojiStorage implements RecentEmojiStorage {
  List<String> _items = [];

  @override
  Future<List<String>> load() async => List.unmodifiable(_items);

  @override
  Future<void> save(List<String> emojiChars) async {
    _items = List.of(emojiChars);
  }
}
