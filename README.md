# emoji_picker_i18n

A **multilingual** emoji picker for Flutter — localized emoji search in **28 languages at once**, powered by Unicode CLDR data via [Emojibase](https://emojibase.dev), the same data source Apple's and Google's keyboards use. On top of the multilingual search it also adds **Korean initial-consonant search** and **Japanese kana search**, the kind you get from those keyboards, now as a Flutter widget.

```dart
// Every loaded language is searched at the same time.
search.search('cat');   // 🐈 🐱 😺 …  English
search.search('gato');  // 🐈 🐱 …      Spanish
search.search('chat');  // 🐈 🐱 …      French
search.search('Katze'); // 🐈 🐱 …      German
```

## Why another emoji picker?

Existing Flutter emoji pickers search in only a handful of Western languages. If your users speak Korean, Thai, Vietnamese, Ukrainian, Hindi, and so on, they can't find emoji in their own language. This package fills that gap:

- **28 languages built in**, searchable simultaneously — one picker finds `cat`, `gato`, and `chat`.
- **Ranked results** — a six-tier ranking (exact > prefix > contains, name before tags) puts the best match first.
- **Old-device tofu (□) filtering** — detects which emoji the device can actually render and hides the rest, using the same "probe a representative emoji" technique as Google's official Android picker, but in pure Dart so it works on iOS, desktop, and web too.
- **Extras for Korean and Japanese** — initial-consonant and kana search, described below.

## Install

```yaml
dependencies:
  emoji_picker_i18n: ^1.0.1
```

## Usage

Language data is **not** bundled automatically — import only the locales you need, so unused languages are tree-shaken out of your app.

```dart
import 'package:emoji_picker_i18n/emoji_picker_i18n.dart';
import 'package:emoji_picker_i18n/locales/en.dart';
import 'package:emoji_picker_i18n/locales/es.dart';

// Build the search engine once and reuse it — it builds an index up front.
final search = EmojiSearch(
  common: kEmojiCommon,
  locales: [kEmojiLocaleEn, kEmojiLocaleEs], // first locale = display language
);

EmojiPickerI18n(
  search: search,
  onEmojiSelected: (emoji) => print(emoji.char),
);
```

### Korean initial-consonant search

Korean users expect keyboard-grade search: typing only the initial consonants, or a half-finished word, should still find the emoji. This package does all of it (examples use the Korean word for "cat"):

```dart
search.search('고양이'); // 🐈 🐱 …   full word
search.search('ㄱㅇㅇ');  // 🐈 🐱 …   initial consonants only
search.search('고ㅇ');   // 🐈 …       mixed syllable + consonant
search.search('고양ㅇ'); // 🐈 …       half-typed last character
```

Compound consonants and vowels are decomposed in typing order, and spaces are ignored (`검은고양이` matches `검은 고양이`).

### Japanese kana search

Japanese IMEs produce hiragana first, but the source data stores keywords in katakana. The engine normalizes between the two with Unicode arithmetic — no dictionary — so all three writings match (examples use the Japanese word for "cat"):

```dart
search.search('ねこ'); // 🐱 …  hiragana
search.search('ネコ'); // 🐱 …  katakana
search.search('猫');   // 🐱 …  kanji
```

### Filtering emoji the device can't render (recommended)

On older phones, newer emoji show up as empty boxes (□). Detect the device's supported version once and pass it to the engine:

```dart
final maxVersion = await detectMaxEmojiVersion(); // pure Dart, all platforms
final search = EmojiSearch(
  common: kEmojiCommon,
  locales: [kEmojiLocaleEn, kEmojiLocaleEs],
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
    hintText: 'Search',
    noResultsText: 'No results',
  ),

  // Category tab labels — pass the generated constant for your language
  categoryBarConfig: const EmojiCategoryBarConfig(
    labels: kEmojiGroupNamesEn,
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
    label: 'Recently used',
    emptyText: 'No emoji used yet',
  ),
)
```

### Recently used storage

Recents persist to `shared_preferences` out of the box. To store them in your own database instead, implement `RecentEmojiStorage` and pass it via `EmojiRecentsConfig(storage: ...)`.

### Search without the UI

The engine is independent of the widget — use it for your own layout, a chat autocomplete, and so on.

```dart
final results = search.search('cat'); // List<Emoji>
for (final e in results) {
  print('${e.char}  ${e.label}  ${e.tags}');
}
```

## Supported languages

28 languages — every language [Emojibase](https://emojibase.dev), the upstream data source, currently ships. Support for more languages, sourced directly from Unicode CLDR (which carries emoji annotations for far more), is planned for a later release.

Import the matching file from `package:emoji_picker_i18n/locales/<code>.dart` and pass its `kEmojiLocale<Code>` constant. Each language also ships a `kEmojiGroupNames<Code>` constant for category labels.

| Language | Code | Language | Code |
|---|---|---|---|
| Bengali | `bn` | Korean | `ko` |
| Danish | `da` | Lithuanian | `lt` |
| German | `de` | Malay | `ms` |
| English | `en` | Norwegian Bokmål | `nb` |
| English (UK) | `en_gb` | Dutch | `nl` |
| Spanish | `es` | Polish | `pl` |
| Spanish (Mexico) | `es_mx` | Portuguese | `pt` |
| Estonian | `et` | Russian | `ru` |
| Finnish | `fi` | Swedish | `sv` |
| French | `fr` | Thai | `th` |
| Hindi | `hi` | Ukrainian | `uk` |
| Hungarian | `hu` | Vietnamese | `vi` |
| Italian | `it` | Chinese (Simplified) | `zh` |
| Japanese | `ja` | Chinese (Traditional) | `zh_hant` |

## Known limitations

- **Emoji size vs. cell size.** Flutter's text engine measures line height from the base text font, not the color-emoji font, so a color glyph can be slightly taller than its line box — a platform-level quirk ([flutter#119623](https://github.com/flutter/flutter/issues/119623)). The picker compensates with default line-height slack and by not hard-clipping cells, so emoji render fully at the default sizes. If you set an unusually large `emojiSize` against a small `cellExtent`, some bottom clipping can reappear; give the cell a little more room (`cellExtent`) or a slightly smaller `emojiSize`.
- **Runtime locale downloads** are planned for a later release; today, languages are compiled in via import.

## License

MIT
