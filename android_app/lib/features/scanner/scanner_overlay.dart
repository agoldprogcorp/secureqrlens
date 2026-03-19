import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/verdict.dart';

class ScannerOverlay extends StatelessWidget {
  final Verdict? verdict;
  final List<Offset> qrCorners;
  final Size imageSize;

  const ScannerOverlay({
    super.key,
    this.verdict,
    this.qrCorners = const [],
    this.imageSize = Size.zero,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _OverlayPainter(
            verdict: verdict,
            qrCorners: qrCorners,
            imageSize: imageSize,
            widgetSize: Size(constraints.maxWidth, constraints.maxHeight),
          ),
        );
      },
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final Verdict? verdict;
  final List<Offset> qrCorners;
  final Size imageSize;
  final Size widgetSize;

  _OverlayPainter({
    required this.verdict,
    required this.qrCorners,
    required this.imageSize,
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
        return const Color(0xFF90CAF9);
    }
  }

  Offset _transformCorner(Offset point) {
    if (imageSize == Size.zero) return point;
    final scaleX = widgetSize.width / imageSize.width;
    final scaleY = widgetSize.height / imageSize.height;
    final scale = max(scaleX, scaleY);
    final offsetX = (widgetSize.width - imageSize.width * scale) / 2;
    final offsetY = (widgetSize.height - imageSize.height * scale) / 2;
    return Offset(point.dx * scale + offsetX, point.dy * scale + offsetY);
  }

  Rect _viewfinderRect() {
    final side = min(widgetSize.width, widgetSize.height) * 0.62;
    final cx = widgetSize.width / 2;
    final cy = widgetSize.height / 2 - 30;
    return Rect.fromCenter(center: Offset(cx, cy), width: side, height: side);
  }

  void _drawCornerBrackets(Canvas canvas, List<Offset> pts, Paint paint,
      double cornerLen) {
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

  void _drawRectBrackets(Canvas canvas, Rect rect, Paint paint,
      double cornerLen) {
    final pts = [
      rect.topLeft,
      rect.topRight,
      rect.bottomRight,
      rect.bottomLeft,
    ];
    _drawCornerBrackets(canvas, pts, paint, cornerLen);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final hasCornersData = qrCorners.length == 4 && imageSize != Size.zero;

    if (hasCornersData && _hasVerdict) {
      // --- Mode A: precise polygon around detected QR code ---
      final pts = qrCorners.map(_transformCorner).toList();
      final path = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (int i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      path.close();

      canvas.drawPath(
        path,
        Paint()..color = _color.withValues(alpha: 0.22),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = _color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeJoin = StrokeJoin.round,
      );

      _drawCornerBrackets(
        canvas,
        pts,
        Paint()
          ..color = _color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round,
        22.0,
      );
    } else {
      // --- Mode B: centered viewfinder square (works on all devices) ---
      final rect = _viewfinderRect();

      // Dim the area outside the viewfinder
      final outer = Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
      final inner = Path()..addRect(rect);
      final mask = Path.combine(PathOperation.difference, outer, inner);
      canvas.drawPath(
        mask,
        Paint()..color = Colors.black.withValues(alpha: 0.45),
      );

      if (_hasVerdict) {
        // Colored fill inside viewfinder
        canvas.drawRect(
          rect,
          Paint()..color = _color.withValues(alpha: 0.20),
        );
        // Solid colored border
        canvas.drawRect(
          rect,
          Paint()
            ..color = _color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }

      // Corner brackets (always visible — color depends on verdict)
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
      old.verdict != verdict ||
      old.qrCorners != qrCorners ||
      old.imageSize != imageSize;
}
