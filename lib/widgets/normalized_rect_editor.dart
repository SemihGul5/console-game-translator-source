import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/subtitle_settings.dart';

/// A draggable, eight-handle editor whose public geometry stays normalized.
class NormalizedRectEditor extends StatefulWidget {
  const NormalizedRectEditor({
    required this.value,
    required this.onChanged,
    required this.label,
    required this.color,
    this.fillArea = true,
    super.key,
  });

  final NormalizedRect value;
  final ValueChanged<NormalizedRect> onChanged;
  final String label;
  final Color color;
  final bool fillArea;

  @override
  State<NormalizedRectEditor> createState() => _NormalizedRectEditorState();
}

class _NormalizedRectEditorState extends State<NormalizedRectEditor> {
  static const _minSize = 0.04;
  static const _hitRadius = 22.0;
  String? _handle;
  Rect? _startRect;
  Offset? _startPoint;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onPanStart: (details) {
      final size = context.size;
      if (size == null || size.isEmpty) return;
      final start = widget.value.rect;
      _startRect = start;
      _startPoint = Offset(
        details.localPosition.dx / size.width,
        details.localPosition.dy / size.height,
      );
      _handle =
          _hitHandle(details.localPosition, size, start) ??
          (start.contains(
                Offset(
                  details.localPosition.dx / size.width,
                  details.localPosition.dy / size.height,
                ),
              )
              ? 'move'
              : 'new');
      if (_handle == 'new') {
        widget.onChanged(
          NormalizedRect.fromRect(
            Rect.fromPoints(_startPoint!, _startPoint!).inflate(_minSize / 2),
          ),
        );
      }
    },
    onPanUpdate: (details) {
      final size = context.size;
      final startRect = _startRect;
      final startPoint = _startPoint;
      final handle = _handle;
      if (size == null ||
          startRect == null ||
          startPoint == null ||
          handle == null) {
        return;
      }
      final current = Offset(
        (details.localPosition.dx / size.width).clamp(0.0, 1.0),
        (details.localPosition.dy / size.height).clamp(0.0, 1.0),
      );
      final delta = current - startPoint;
      Rect next;
      if (handle == 'new') {
        next = Rect.fromPoints(startPoint, current);
      } else if (handle == 'move') {
        final left = (startRect.left + delta.dx)
            .clamp(0.0, 1.0 - startRect.width)
            .toDouble();
        final top = (startRect.top + delta.dy)
            .clamp(0.0, 1.0 - startRect.height)
            .toDouble();
        next = Rect.fromLTWH(left, top, startRect.width, startRect.height);
      } else {
        next = _resize(startRect, handle, delta);
      }
      next = _keepUsable(next);
      widget.onChanged(NormalizedRect.fromRect(next));
    },
    onPanEnd: (_) {
      _handle = null;
      _startRect = null;
      _startPoint = null;
    },
    child: CustomPaint(
      painter: _NormalizedRectPainter(
        rect: widget.value.rect,
        color: widget.color,
        label: widget.label,
        fillArea: widget.fillArea,
      ),
      child: const SizedBox.expand(),
    ),
  );

  String? _hitHandle(Offset point, Size size, Rect rect) {
    final handles = <String, Offset>{
      'nw': Offset(rect.left * size.width, rect.top * size.height),
      'n': Offset(rect.center.dx * size.width, rect.top * size.height),
      'ne': Offset(rect.right * size.width, rect.top * size.height),
      'e': Offset(rect.right * size.width, rect.center.dy * size.height),
      'se': Offset(rect.right * size.width, rect.bottom * size.height),
      's': Offset(rect.center.dx * size.width, rect.bottom * size.height),
      'sw': Offset(rect.left * size.width, rect.bottom * size.height),
      'w': Offset(rect.left * size.width, rect.center.dy * size.height),
    };
    for (final entry in handles.entries) {
      if ((entry.value - point).distance <= _hitRadius) return entry.key;
    }
    return null;
  }

  Rect _resize(Rect rect, String handle, Offset delta) {
    var left = rect.left;
    var top = rect.top;
    var right = rect.right;
    var bottom = rect.bottom;
    if (handle.contains('w')) {
      left = (left + delta.dx).clamp(0.0, right - _minSize);
    }
    if (handle.contains('e')) {
      right = (right + delta.dx).clamp(left + _minSize, 1.0);
    }
    if (handle.contains('n')) {
      top = (top + delta.dy).clamp(0.0, bottom - _minSize);
    }
    if (handle.contains('s')) {
      bottom = (bottom + delta.dy).clamp(top + _minSize, 1.0);
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  Rect _keepUsable(Rect rect) {
    var left = rect.left.clamp(0.0, 1.0 - _minSize).toDouble();
    var top = rect.top.clamp(0.0, 1.0 - _minSize).toDouble();
    var right = rect.right.clamp(left + _minSize, 1.0).toDouble();
    var bottom = rect.bottom.clamp(top + _minSize, 1.0).toDouble();
    if (rect.width < 0) {
      left = rect.left.clamp(0.0, 1.0 - _minSize).toDouble();
      right = math.min(1, left + _minSize);
    }
    if (rect.height < 0) {
      top = rect.top.clamp(0.0, 1.0 - _minSize).toDouble();
      bottom = math.min(1, top + _minSize);
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }
}

class _NormalizedRectPainter extends CustomPainter {
  const _NormalizedRectPainter({
    required this.rect,
    required this.color,
    required this.label,
    required this.fillArea,
  });

  final Rect rect;
  final Color color;
  final String label;
  final bool fillArea;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Rect.fromLTRB(
      rect.left * size.width,
      rect.top * size.height,
      rect.right * size.width,
      rect.bottom * size.height,
    );
    final fill = Paint()..color = color.withValues(alpha: 0.18);
    final border = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    if (fillArea) canvas.drawRect(box, fill);
    canvas.drawRect(box, border);
    final handlePaint = Paint()..color = color;
    for (final point in <Offset>[
      box.topLeft,
      Offset(box.center.dx, box.top),
      box.topRight,
      Offset(box.right, box.center.dy),
      box.bottomRight,
      Offset(box.center.dx, box.bottom),
      box.bottomLeft,
      Offset(box.left, box.center.dy),
    ]) {
      canvas.drawCircle(point, 7, handlePaint);
    }
    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 3)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    text.paint(
      canvas,
      Offset(box.left + 6, math.max(0, box.top - text.height - 4)),
    );
  }

  @override
  bool shouldRepaint(covariant _NormalizedRectPainter oldDelegate) =>
      oldDelegate.rect != rect ||
      oldDelegate.color != color ||
      oldDelegate.fillArea != fillArea ||
      oldDelegate.label != label;
}
