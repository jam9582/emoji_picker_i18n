import 'package:emoji_picker_i18n/emoji_picker_i18n.dart';
import 'package:emoji_picker_i18n/locales/en.dart';
import 'package:emoji_picker_i18n/locales/ko.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'emoji_picker_i18n example',
      // 피커는 앱 테마를 자동으로 따르므로, 데모는 무난한 회색 계열로
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const PickerDemoPage(),
    );
  }
}

class PickerDemoPage extends StatefulWidget {
  const PickerDemoPage({super.key});

  @override
  State<PickerDemoPage> createState() => _PickerDemoPageState();
}

class _PickerDemoPageState extends State<PickerDemoPage> {
  // 색인 구축은 1회면 충분하므로 State 필드로 보관
  final _search = EmojiSearch(
    common: kEmojiCommon,
    locales: [kEmojiLocaleKo, kEmojiLocaleEn],
  );

  Emoji? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('emoji_picker_i18n')),
      // 데스크톱에서도 폰 화면 폭으로 미리보기 (폰에서는 영향 없음)
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      children: [
        // 선택 결과 표시 영역
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _selected?.char ?? '❔',
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(width: 16),
              // Flexible이 있어야 남은 폭을 한도로 말줄임(...)이 동작한다
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selected?.label ?? '아래에서 골라보세요',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (_selected != null)
                      Text(
                        _selected!.tags.join(', '),
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // 피커 — '고양이', 'ㄱㅇㅇ', '고ㅇ', 'cat' 모두 검색됩니다
        Expanded(
          child: EmojiPickerI18n(
            search: _search,
            searchBarConfig: const EmojiSearchBarConfig(
              hintText: '검색 (초성 ㄱㅇㅇ도 됩니다)',
              noResultsText: '검색 결과가 없어요',
            ),
            categoryBarConfig: const EmojiCategoryBarConfig(
              labels: kEmojiGroupNamesKo,
            ),
            recentsConfig: const EmojiRecentsConfig(
              label: '최근 사용',
              emptyText: '아직 사용한 이모지가 없어요',
            ),
            onEmojiSelected: (emoji) => setState(() => _selected = emoji),
          ),
        ),
      ],
    );
  }
}
