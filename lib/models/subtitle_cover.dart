import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'subtitle_settings.dart';

/// Stands in a translation where a controller button icon is drawn.
const String buttonIconPlaceholder = '￼';

final LinkedHashMap<String, Uint8List> _iconBytes =
    LinkedHashMap<String, Uint8List>();

/// The PNG bytes of a button icon sent as base64. The same icon always gets
/// the same bytes object, so its image is decoded once and never flickers.
Uint8List? buttonIconBytes(String base64Png) {
  final cached = _iconBytes.remove(base64Png);
  if (cached != null) {
    _iconBytes[base64Png] = cached;
    return cached;
  }
  try {
    final bytes = base64Decode(base64Png);
    _iconBytes[base64Png] = bytes;
    while (_iconBytes.length > 32) {
      _iconBytes.remove(_iconBytes.keys.first);
    }
    return bytes;
  } on FormatException {
    return null;
  }
}

List<String> _iconList(Object? value) => value is List
    ? value.whereType<String>().where((icon) => icon.isNotEmpty).toList()
    : const <String>[];

/// A translation with controller button icons cut from the game picture.
/// [text] holds [buttonIconPlaceholder] where each icon of [icons] goes.
@immutable
class SubtitleRichText {
  const SubtitleRichText({required this.text, required this.icons});

  final String text;
  final List<String> icons;

  static SubtitleRichText? fromEvent(Map event) {
    final text = event['richText'];
    final icons = _iconList(event['icons']);
    if (text is! String || icons.isEmpty) return null;
    if (!text.contains(buttonIconPlaceholder)) return null;
    return SubtitleRichText(text: text, icons: icons);
  }

  Map<String, Object> toMap() => {'text': text, 'icons': icons};
}

/// One translation drawn directly over the English subtitle line it came from.
///
/// Coordinates are fractions of the video frame, like the OCR areas. The native
/// side keeps [id] stable while the same line stays on screen, so widgets and
/// TV windows can be reused instead of being rebuilt on every frame.
@immutable
class SubtitleCover {
  const SubtitleCover({
    required this.id,
    required this.text,
    required this.rect,
    required this.lineHeight,
    this.icons = const <String>[],
  });

  final int id;
  final String text;
  final NormalizedRect rect;
  final double lineHeight;

  /// Button icons (base64 PNG) drawn where [text] holds the placeholder.
  final List<String> icons;

  static SubtitleCover? tryParse(Object? value) {
    if (value is! Map) return null;
    final id = value['id'];
    final text = value['text'];
    if (id is! num || text is! String || text.trim().isEmpty) return null;
    double? read(String key) {
      final raw = value[key];
      return raw is num && raw.isFinite ? raw.toDouble() : null;
    }

    final left = read('left');
    final top = read('top');
    final width = read('width');
    final height = read('height');
    if (left == null || top == null || width == null || height == null) {
      return null;
    }
    if (width <= 0 || height <= 0) return null;
    final clampedLeft = left.clamp(0.0, 1.0).toDouble();
    final clampedTop = top.clamp(0.0, 1.0).toDouble();
    return SubtitleCover(
      id: id.toInt(),
      text: text,
      rect: NormalizedRect(
        left: clampedLeft,
        top: clampedTop,
        width: width.clamp(0.0, 1.0 - clampedLeft).toDouble(),
        height: height.clamp(0.0, 1.0 - clampedTop).toDouble(),
      ),
      lineHeight: (read('lineHeight') ?? height).clamp(0.005, 0.5).toDouble(),
      icons: _iconList(value['icons']),
    );
  }

  Map<String, Object> toMap() => {
    'id': id,
    'text': text,
    ...rect.toMap(),
    'lineHeight': lineHeight,
    if (icons.isNotEmpty) 'icons': icons,
  };
}
