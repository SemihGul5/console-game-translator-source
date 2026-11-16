import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/game_catalog_entry.dart';
import '../l10n/app_localizations.dart';

class GameCoverCard extends StatefulWidget {
  // Every game uses the same portrait frame and two-line title area.
  static const coverAspectRatio = 2 / 3;

  static double titleHeight(TextScaler scaler) =>
      (scaler.scale(12) * 1.3).ceilToDouble() * 2;

  static double languageHeight(TextScaler scaler) =>
      (scaler.scale(9) * 1.4).ceilToDouble();

  static double heightFor(double width, TextScaler scaler) =>
      width / coverAspectRatio +
      titleHeight(scaler) +
      languageHeight(scaler) +
      20;

  const GameCoverCard({
    super.key,
    required this.game,
    required this.selected,
    required this.downloading,
    required this.preparing,
    required this.onTap,
    required this.loadCover,
    this.downloaded = false,
    this.onLongPress,
  });

  final GameCatalogEntry game;
  final bool selected;
  final bool downloading;
  final bool downloaded;
  final bool preparing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Future<Uint8List?> Function(GameCatalogEntry) loadCover;

  @override
  State<GameCoverCard> createState() => _GameCoverCardState();
}

class _GameCoverCardState extends State<GameCoverCard> {
  late Future<Uint8List?> _cover;

  @override
  void initState() {
    super.initState();
    _cover = widget.loadCover(widget.game);
  }

  @override
  void didUpdateWidget(GameCoverCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.game.coverKey != oldWidget.game.coverKey) {
      _cover = widget.loadCover(widget.game);
    }
  }

  Widget _placeholder() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF183A5E), Color(0xFF101A2E)],
      ),
    ),
    alignment: Alignment.center,
    child: const Icon(
      Icons.sports_esports_rounded,
      color: Color(0xFF6387AE),
      size: 28,
    ),
  );

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF4DE2D0);
    return Semantics(
      button: true,
      selected: widget.selected,
      enabled: widget.onTap != null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: widget.selected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.08),
                    blurRadius: 10,
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: const Color(0xFF131E30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: widget.selected ? accent : const Color(0xFF293B54),
              width: widget.selected ? 1.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: GameCoverCard.coverAspectRatio,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FutureBuilder<Uint8List?>(
                        future: _cover,
                        builder: (context, snapshot) => snapshot.data == null
                            ? _placeholder()
                            : Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                                cacheWidth: 320,
                                excludeFromSemantics: true,
                                errorBuilder: (_, _, _) => _placeholder(),
                              ),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.5, 1],
                            colors: [Colors.transparent, Color(0x55101829)],
                          ),
                        ),
                      ),
                      if (widget.selected &&
                          !widget.downloading &&
                          !widget.preparing)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              boxShadow: const [
                                BoxShadow(color: Colors.black45, blurRadius: 8),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Color(0xFF062E2C),
                              size: 14,
                            ),
                          ),
                        ),
                      if (widget.downloading)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: LinearProgressIndicator(
                            minHeight: 3,
                            semanticsLabel: context.tr(
                              'Çeviri dosyası indiriliyor…',
                            ),
                          ),
                        ),
                      if (widget.downloaded && !widget.downloading)
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Tooltip(
                            key: ValueKey('game-downloaded-${widget.game.id}'),
                            message: context.tr('İndirildi'),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xE6101729),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.6),
                                ),
                              ),
                              child: const Icon(
                                Icons.download_done_rounded,
                                color: accent,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      if (widget.downloading || widget.preparing)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xCC0A1624),
                              shape: BoxShape.circle,
                            ),
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: widget.downloading
                                  ? const Icon(
                                      Icons.download_rounded,
                                      color: accent,
                                      size: 24,
                                    )
                                  : Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: accent,
                                          semanticsLabel: context.tr(
                                            'Çeviri belleğe yükleniyor…',
                                          ),
                                        ),
                                        const Icon(
                                          Icons.memory_rounded,
                                          color: accent,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: GameCoverCard.titleHeight(
                          MediaQuery.textScalerOf(context),
                        ),
                        child: Text(
                          widget.game.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: GameCoverCard.languageHeight(
                          MediaQuery.textScalerOf(context),
                        ),
                        child: Text(
                          '${widget.game.sourceLanguage.toUpperCase()} → ${widget.game.targetLanguage.toUpperCase()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: widget.selected
                                ? accent
                                : const Color(0xFF91A6C2),
                            fontSize: 9,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
