import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/verdict.dart';

class ScannerOverlay extends StatelessWidget {
  final Verdict? verdict;

  const ScannerOverlay({
    super.key,
    this.verdict,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _OverlayPainter(
            verdict: verdict,
            widgetSize: Size(constraints.maxWidth, constraints.maxHeight),
          ),
        );
      },
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final Verdict? verdict;
  final Size widgetSize;

  _OverlayPainter({
    required this.verdict,
    required this.widgetSize,
  });

  bool get _hasVerdict => verdict != null && verdict != Verdict.unknown;

  Color get _color {
    switch (verdict) {
      case Verdict.safe:
        return const Color(0xFF4CAF50);
      case Verdict.suspicious:
        return const Color(0xFFFFC107);
      case Verdict.danger:
        return const Color(0xFFF44336);
      default:
        return Colors.white;
    }
  }

  Rect _viewfinderRect() {
    final side = min(widgetSize.width, widgetSize.height) * 0.62;
    final cx = widgetSize.width / 2;
    final cy = widgetSize.height / 2 - 30;
    return Rect.fromCenter(center: Offset(cx, cy), width: side, height: side);
  }

  void _drawRectBrackets(
      Canvas canvas, Rect rect, Paint paint, double cornerLen) {
    final pts = [
      rect.topLeft,
      rect.topRight,
      rect.bottomRight,
      rect.bottomLeft,
    ];
    for (int i = 0; i < 4; i++) {
      final curr = pts[i];
      final next = pts[(i + 1) % 4];
      final prev = pts[(i + 3) % 4];
      final dn = _norm(next, curr, cornerLen);
      final dp = _norm(prev, curr, cornerLen);
      canvas.drawLine(curr, Offset(curr.dx + dn.dx, curr.dy + dn.dy), paint);
      canvas.drawLine(curr, Offset(curr.dx + dp.dx, curr.dy + dp.dy), paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = _viewfinderRect();

    // Dimming outside viewfinder
    final outer = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final inner = Path()..addRect(rect);
    final mask = Path.combine(PathOperation.difference, outer, inner);
    canvas.drawPath(
      mask,
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );

    if (_hasVerdict) {
      canvas.drawRect(
        rect,
        Paint()..color = _color.withValues(alpha: 0.20),
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = _color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    // Corner brackets
    final bracketColor = _hasVerdict ? _color : Colors.white;
    _drawRectBrackets(
      canvas,
      rect,
      Paint()
        ..color = bracketColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = _hasVerdict ? 7 : 5
        ..strokeCap = StrokeCap.round,
      28.0,
    );
  }

  Offset _norm(Offset target, Offset origin, double length) {
    final dx = target.dx - origin.dx;
    final dy = target.dy - origin.dy;
    final d = sqrt(dx * dx + dy * dy);
    if (d == 0) return Offset.zero;
    return Offset(dx / d * length, dy / d * length);
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter old) =>
      old.verdict != verdict;
}
