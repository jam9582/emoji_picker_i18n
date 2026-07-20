## 1.0.1

Documentation and metadata only — no code changes.

* Lead with multilingual search; Korean initial-consonant and Japanese kana search are now presented as additional features.
* Language-neutral (English) examples throughout, with Korean and Japanese examples kept to their dedicated sections.
* List supported languages by full name, not just code.
* Add `topics` and align the package description.

## 1.0.0

First public release.

### Search

* **28 languages built in**, all searchable at once — one picker finds both `고양이` and `cat`. Powered by Unicode CLDR data via [Emojibase](https://emojibase.dev).
* **Keyboard-grade Korean search** — initial consonants (`ㄱㅇㅇ`), mixed syllable + consonant (`고ㅇ`), and half-typed input (`고양ㅇ`), plus whitespace-insensitive matching.
* **Japanese kana normalization** — `ねこ`, `ネコ`, and `猫` all match, with no dictionary (Unicode arithmetic).
* Six-tier ranking (exact > prefix > contains, name before tags) so the best match comes first.
* The search engine (`EmojiSearch`) is usable on its own, independent of the widget.

### Rendering & device support

* **Old-device tofu (□) filtering** — `detectMaxEmojiVersion()` measures which emoji the device can actually render (pure Dart, works on iOS, desktop, and web too) and `EmojiSearch(maxEmojiVersion:)` hides the rest. Only late-added skin-tone variants are dropped; base emoji always stay. Detection failure falls back to showing everything.
* Emoji normalization (`normalizeEmoji`, `sameEmoji`) so presentation-selector differences (U+FE0F) don't break recents deduplication.

### Widget

* `EmojiPickerI18n` widget with always-on live search, category tabs, skin-tone long-press picker, and recently used.
* Fully configurable via `EmojiPickerTheme` and the per-part configs (`EmojiSearchBarConfig`, `EmojiCategoryBarConfig`, `EmojiGridConfig`, `EmojiSkinToneConfig`, `EmojiRecentsConfig`) — search bar and category bar can sit at the top or bottom.
* Colors fall back to the app's `ColorScheme` (light/dark for free) when no theme is given.
* Pluggable recents storage via `RecentEmojiStorage`; defaults to `shared_preferences`.
