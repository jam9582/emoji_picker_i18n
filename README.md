# emoji_picker_i18n

A multilingual emoji picker for Flutter with **localized emoji search in 28 languages**, including **Korean *chosung* (initial-consonant) search** — the kind of search you get from the Apple and Google keyboards, now as a Flutter widget. Powered by Unicode CLDR data via [Emojibase](https://emojibase.dev), the same data source those keyboards use.

```dart
search.search('고양이'); // 🐈 🐱 😺 …
search.search('ㄱㅇㅇ');  // 🐈 🐱 …  (type only initial consonants)
search.search('고ㅇ');   // 🐈 …      (works mid-typing, like contact search)
search.search('cat');    // 🐈 🐱 …  (every loaded locale searched at once)
```

## Why another emoji picker?

Existing Flutter emoji pickers search in only a handful of Western languages. If your users speak Korean, Thai, Vietnamese, Ukrainian, Hindi, and so on, they can't find emoji in their own language. This package fills that gap:

- **28 languages built in**, searchable simultaneously — one picker finds both `고양이` and `cat`.
- **Keyboard-grade Korean search** — initial consonants (`ㄱㅇㅇ`), mixed syllable + consonant (`고ㅇ`), and half-typed input (`고양ㅇ`), plus whitespace-insensitive matching.
- **Japanese kana normalization** — `ねこ`, `ネコ`, and `猫` all match, with no dictionary (Unicode arithmetic).
- **Old-device tofu (□) filtering** — detects which emoji the device can actually render and hides the rest, using the same "probe a representative emoji" technique as Google's official Android picker, but in pure Dart so it works on iOS, desktop, and web too.

## Install

```yaml
dependencies:
  emoji_picker_i18n: ^1.0.0
```

## Usage

Language data is **not** bundled automatically — import only the locales you need, so unused languages are tree-shaken out of your app.

```dart
import 'package:emoji_picker_i18n/emoji_picker_i18n.dart';
import 'package:emoji_picker_i18n/locales/ko.dart';
import 'package:emoji_picker_i18n/locales/en.dart';

// Build the search engine once and reuse it — it builds an index up front.
final search = EmojiSearch(
  common: kEmojiCommon,
  locales: [kEmojiLocaleKo, kEmojiLocaleEn], // first locale = display language
);

EmojiPickerI18n(
  search: search,
  onEmojiSelected: (emoji) => print(emoji.char),
);
```

### Filtering emoji the device can't render (recommended)

On older phones, newer emoji show up as empty boxes (□). Detect the device's supported version once and pass it to the engine:

```dart
final maxVersion = await detectMaxEmojiVersion(); // pure Dart, all platforms
final search = EmojiSearch(
  common: kEmojiCommon,
  locales: [kEmojiLocaleKo, kEmojiLocaleEn],
  maxEmojiVersion: maxVersion, // null = show everything (detection failed)
);
```

Base emoji stay; only skin-tone variants that were added later are dropped (🤝 shows, 🤝🏻 may not). If detection fails it returns `null` and nothing is filtered — a real emoji is never hidden by mistake.

### Customizing

Everything below is optional and has sensible defaults. Colors fall back to your app's `ColorScheme` (light/dark for free).

```dart
EmojiPickerI18n(
  search: search,
  onEmojiSelected: (emoji) => setState(() => _selected = emoji.char),

  // Colors — omit any field to inherit from the app theme
  theme: const EmojiPickerTheme(
    searchFieldColor: Color(0xFFF7F5F2),
    selectedTabColor: Color(0xFFE8DDD3),
  ),

  // Search bar text/icons/placement
  searchBarConfig: const EmojiSearchBarConfig(
    hintText: '검색',
    noResultsText: '검색 결과가 없어요',
  ),

  // Category tab labels — pass the generated constant for your language
  categoryBarConfig: const EmojiCategoryBarConfig(
    labels: kEmojiGroupNamesKo,
  ),

  // Grid sizing
  gridConfig: const EmojiGridConfig(
    cellExtent: 44, // columns auto-fit to width
    emojiSize: 28,
  ),

  // Long-press skin-tone picker
  skinToneConfig: const EmojiSkinToneConfig(
    longPressDelay: Duration(milliseconds: 250),
  ),

  // Recently used
  recentsConfig: const EmojiRecentsConfig(
    label: '최근 사용',
    emptyText: '아직 사용한 이모지가 없어요',
  ),
)
```

### Recently used storage

Recents persist to `shared_preferences` out of the box. To store them in your own database instead, implement `RecentEmojiStorage` and pass it via `EmojiRecentsConfig(storage: ...)`.

### Search without the UI

The engine is independent of the widget — use it for your own layout, a chat autocomplete, and so on.

```dart
final results = search.search('고양이'); // List<Emoji>
for (final e in results) {
  print('${e.char}  ${e.label}  ${e.tags}');
}
```

## Supported languages

`bn da de en en_gb es es_mx et fi fr hi hu it ja ko lt ms nb nl pl pt ru sv th uk vi zh zh_hant`

Import the matching file from `package:emoji_picker_i18n/locales/<code>.dart` and pass its `kEmojiLocale<Code>` constant. Each language also ships a `kEmojiGroupNames<Code>` constant for category labels.

## Known limitations

- **Emoji size vs. cell size.** Flutter's text engine measures line height from the base text font, not the color-emoji font, so a color glyph can be slightly taller than its line box — a platform-level quirk ([flutter#119623](https://github.com/flutter/flutter/issues/119623)). The picker compensates with default line-height slack and by not hard-clipping cells, so emoji render fully at the default sizes. If you set an unusually large `emojiSize` against a small `cellExtent`, some bottom clipping can reappear; give the cell a little more room (`cellExtent`) or a slightly smaller `emojiSize`.
- **Runtime locale downloads** are planned for a later release; today, languages are compiled in via import.

## License

MIT
