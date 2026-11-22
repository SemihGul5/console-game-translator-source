import 'package:flutter/material.dart';

import '../models/subtitle_cover.dart';
import '../models/subtitle_settings.dart';
import '../services/game_fonts.dart';

/// Shared by the live Remote Play overlay and its font rendering tests.
class GameSubtitleText extends StatelessWidget {
  const GameSubtitleText({
    super.key,
    required this.text,
    required this.settings,
    required this.fontSize,
    this.icons = const <String>[],
  });
  final String text;
  final SubtitleSettings settings;
  final double fontSize;

  /// Controller button icons (base64 PNG) drawn where [text] holds
  /// [buttonIconPlaceholder]. Without them the text is drawn as before.
  final List<String> icons;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<LoadedGameFont?>(
    valueListenable: GameFonts.active,
    builder: (context, font, _) => LayoutBuilder(
      builder: (context, constraints) {
        final style = TextStyle(
          fontFamily: settings.useGameFont ? font?.family : null,
          color: Color(settings.textColor),
          fontSize: fontSize,
          height: 1,
          fontWeight: settings.bold ? FontWeight.bold : FontWeight.normal,
          shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
        );
        final rtl = const {
          'ar',
          'fa',
          'he',
          'ur',
        }.contains(settings.targetLanguageCode.split('-').first);
        final direction = rtl ? TextDirection.rtl : TextDirection.ltr;
        final alignment = settings.centered
            ? TextAlign.center
            : (rtl ? TextAlign.right : TextAlign.left);
        final scaler = MediaQuery.textScalerOf(context);
        var fittedSize = fontSize;
        if (text.isNotEmpty &&
            constraints.hasBoundedWidth &&
            constraints.hasBoundedHeight &&
            constraints.maxWidth > 0 &&
            constraints.maxHeight > 0) {
          final painter = TextPainter(
            textDirection: direction,
            textAlign: alignment,
            textScaler: scaler,
            textWidthBasis: TextWidthBasis.longestLine,
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
          );
          bool fits(double size) {
            painter.text = TextSpan(
              // An icon takes about the room of two wide letters.
              text: text.replaceAll(buttonIconPlaceholder, 'MM'),
              style: DefaultTextStyle.of(
                context,
              ).style.merge(style.copyWith(fontSize: size)),
            );
            painter.layout(maxWidth: constraints.maxWidth);
            return painter.height <= constraints.maxHeight &&
                painter.width <= constraints.maxWidth;
          }

          if (!fits(fontSize)) {
            var low = 0.0;
            var high = fontSize;
            for (var step = 0; step < 10; step++) {
              final mid = (low + high) / 2;
              if (fits(mid)) {
                low = mid;
              } else {
                high = mid;
              }
            }
            fittedSize = low;
          }
          painter.dispose();
        }
        final fittedStyle = style.copyWith(fontSize: fittedSize);
        if (icons.isNotEmpty && text.contains(buttonIconPlaceholder)) {
          final parts = text.split(buttonIconPlaceholder);
          final spans = <InlineSpan>[];
          for (var index = 0; index < parts.length; index++) {
            if (parts[index].isNotEmpty) spans.add(TextSpan(text: parts[index]));
            if (index == parts.length - 1) break;
            final bytes = index < icons.length
                ? buttonIconBytes(icons[index])
                : null;
            if (bytes == null) continue;
            spans.add(
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Image.memory(
                  bytes,
                  height: fittedSize * 1.15,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            );
          }
          return Text.rich(
            TextSpan(children: spans),
            textDirection: direction,
            textAlign: alignment,
            textScaler: scaler,
            textWidthBasis: TextWidthBasis.longestLine,
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
            style: fittedStyle,
          );
        }
        return Text(
          text,
          textDirection: direction,
          textAlign: alignment,
          textScaler: scaler,
          textWidthBasis: TextWidthBasis.longestLine,
          textHeightBehavior: const TextHeightBehavior(
            applyHeightToFirstAscent: false,
            applyHeightToLastDescent: false,
          ),
          style: fittedStyle,
        );
      },
    ),
  );
}
