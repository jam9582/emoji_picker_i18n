import 'package:flutter/material.dart';

import '../emoji.dart';

/// 이모지 하나를 탭했을 때의 콜백.
typedef OnEmojiSelected = void Function(Emoji emoji);

/// 이모지 격자.
///
/// 피커의 가장 안쪽 부품. 카테고리 페이지와 검색 결과가 모두 이 위젯으로
/// 그려진다. 스크롤은 GridView.builder의 지연 생성에 맡긴다.
class EmojiGrid extends StatelessWidget {
  const EmojiGrid({
    super.key,
    required this.emojis,
    required this.onEmojiSelected,
    this.columns = 8,
    this.emojiSize = 28,
    this.padding = const EdgeInsets.all(8),
    this.emptyPlaceholder,
  });

  /// 표시할 이모지 목록 (표준 순서 또는 검색 결과 순서)
  final List<Emoji> emojis;

  final OnEmojiSelected onEmojiSelected;

  /// 한 줄에 표시할 개수
  final int columns;

  /// 이모지 글자 크기
  final double emojiSize;

  final EdgeInsets padding;

  /// 목록이 비었을 때 대신 표시할 위젯 (검색 결과 없음, 최근 사용 없음 등)
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    if (emojis.isEmpty && emptyPlaceholder != null) {
      return Center(child: emptyPlaceholder);
    }
    return GridView.builder(
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
      ),
      itemCount: emojis.length,
      itemBuilder: (context, index) {
        final emoji = emojis[index];
        return InkWell(
          key: ValueKey(emoji.char),
          borderRadius: BorderRadius.circular(8),
          onTap: () => onEmojiSelected(emoji),
          child: Center(
            child: Text(
              emoji.char,
              style: TextStyle(fontSize: emojiSize),
            ),
          ),
        );
      },
    );
  }
}
