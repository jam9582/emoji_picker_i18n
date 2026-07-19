import 'package:flutter/material.dart';

import '../emoji.dart';
import 'emoji_picker_config.dart';

/// 이모지 하나를 탭했을 때의 콜백.
typedef OnEmojiSelected = void Function(Emoji emoji);

/// 피부색 변형이 있는 이모지를 길게 눌렀을 때의 콜백.
/// [cellRect]는 눌린 셀의 화면 기준 위치 (오버레이 배치용).
typedef OnEmojiLongPressed = void Function(Emoji emoji, Rect cellRect);

/// 이모지 격자.
///
/// 피커의 가장 안쪽 부품. 카테고리 페이지와 검색 결과가 모두 이 위젯으로
/// 그려진다. 스크롤은 GridView.builder의 지연 생성에 맡긴다.
class EmojiGrid extends StatelessWidget {
  const EmojiGrid({
    super.key,
    required this.emojis,
    required this.onEmojiSelected,
    this.onEmojiLongPressed,
    this.config = const EmojiGridConfig(),
    this.emptyPlaceholder,
  });

  /// 표시할 이모지 목록 (표준 순서 또는 검색 결과 순서)
  final List<Emoji> emojis;

  final OnEmojiSelected onEmojiSelected;

  /// 피부색 변형 보유 이모지의 롱프레스 콜백.
  /// null이면 롱프레스 비활성 + 변형 보유 표시(점)도 그리지 않는다.
  final OnEmojiLongPressed? onEmojiLongPressed;

  /// 크기·간격·여백·텍스트 스타일 설정
  final EmojiGridConfig config;

  /// 목록이 비었을 때 대신 표시할 위젯 (검색 결과 없음, 최근 사용 없음 등)
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    if (emojis.isEmpty && emptyPlaceholder != null) {
      return Center(child: emptyPlaceholder);
    }
    // 커스텀 폰트 등은 emojiTextStyle로 받되 크기는 emojiSize로 통일
    final emojiStyle = (config.emojiTextStyle ?? const TextStyle())
        .copyWith(fontSize: config.emojiSize);

    return GridView.builder(
      padding: config.padding,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: config.cellExtent,
        crossAxisSpacing: config.horizontalSpacing,
        mainAxisSpacing: config.verticalSpacing,
      ),
      itemCount: emojis.length,
      itemBuilder: (context, index) {
        final emoji = emojis[index];
        final hasSkins = onEmojiLongPressed != null && emoji.skins.isNotEmpty;

        return Builder(
          key: ValueKey(emoji.char),
          builder: (cellContext) => InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onEmojiSelected(emoji),
            onLongPress: hasSkins
                ? () {
                    final box = cellContext.findRenderObject() as RenderBox;
                    onEmojiLongPressed!(
                      emoji,
                      box.localToGlobal(Offset.zero) & box.size,
                    );
                  }
                : null,
            child: Stack(
              children: [
                Center(
                  child: Text(emoji.char, style: emojiStyle),
                ),
                if (hasSkins)
                  Positioned(
                    right: 3,
                    bottom: 3,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
