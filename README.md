# emoji_picker_i18n

> 🚧 **Work in progress** — not yet published to pub.dev. APIs may change without notice.

A multilingual emoji picker for Flutter with **localized emoji search in 28+ languages**, powered by Unicode CLDR data (via [Emojibase](https://emojibase.dev)) — the same data source Apple and Google keyboards use for emoji search.

## Why another emoji picker?

Existing Flutter emoji pickers support search in only a handful of languages. If your users speak Korean, Thai, Vietnamese, Ukrainian, ... they can't search emoji in their own language. This package aims to fix that — including niceties like Korean *chosung* search:

```dart
search.search('고양이'); // 🐈 🐱 😺 ...
search.search('ㄱㅇㅇ');  // 🐈 🐱 ... (initial-consonant search)
search.search('고ㅇ');   // 🐈 ... (works mid-typing, like contact apps)
search.search('cat');    // 🐈 🐱 ... (all loaded locales searched at once)
```

Only the locales you import are compiled into your app — unused languages are tree-shaken away.

## Status

- [x] Data pipeline: Emojibase → shared core + per-locale keyword data (ko, en; more to come)
- [x] Search engine: substring matching, Korean chosung/jamo matching, exact > prefix > contains ranking
- [x] Emoji string normalization utilities (`sameEmoji('🐈️', '🐈') == true`)
- [ ] Picker UI widget (in progress)
- [ ] Runtime locale pack downloads
- [ ] pub.dev release

## License

MIT
