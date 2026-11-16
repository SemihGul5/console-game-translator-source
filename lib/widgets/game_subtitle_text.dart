import 'package:flutter/material.dart';

import '../models/subtitle_settings.dart';
import '../services/game_fonts.dart';

/// Shared by the live Remote Play overlay and its font rendering tests.
class GameSubtitleText extends StatelessWidget {
  const GameSubtitleText({
    super.key,
    required this.text,
    required this.settings,
    required this.fontSize,
  });
  final String text;
  final SubtitleSettings settings;
  final double fontSize;

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
              text: text,
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
          style: style.copyWith(fontSize: fittedSize),
        );
      },
    ),
  );
}
