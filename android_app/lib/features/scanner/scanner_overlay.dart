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
    final hasVerdict = verdict != null && verdict != Verdict.unknown;
    if (!hasVerdict) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _OverlayPainter(
            verdict: verdict!,
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
  final Verdict verdict;
  final List<Offset> qrCorners;
  final Size imageSize;
  final Size widgetSize;

  _OverlayPainter({
    required this.verdict,
    required this.qrCorners,
    required this.imageSize,
    required this.widgetSize,
  });

  Color get _color {
    switch (verdict) {
      case Verdict.safe:
        return const Color(0xFF4CAF50);
      case Verdict.suspicious:
        return const Color(0xFFFFC107);
      case Verdict.danger:
        return const Color(0xFFF44336);
      default:
        return Colors.transparent;
    }
  }

  Offset _transform(Offset point) {
    if (imageSize == Size.zero) return point;
    final scaleX = widgetSize.width / imageSize.width;
    final scaleY = widgetSize.height / imageSize.height;
    final scale = max(scaleX, scaleY);
    final offsetX = (widgetSize.width - imageSize.width * scale) / 2;
    final offsetY = (widgetSize.height - imageSize.height * scale) / 2;
    return Offset(point.dx * scale + offsetX, point.dy * scale + offsetY);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final hasCorners = qrCorners.length == 4 && imageSize != Size.zero;

    if (hasCorners) {
      final pts = qrCorners.map(_transform).toList();
      final path = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (int i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      path.close();

      canvas.drawPath(path, Paint()..color = _color.withValues(alpha: 0.25));
      canvas.drawPath(
        path,
        Paint()
          ..color = _color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeJoin = StrokeJoin.round,
      );

      const cornerLen = 20.0;
      final cp = Paint()
        ..color = _color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < 4; i++) {
        final curr = pts[i];
        final next = pts[(i + 1) % 4];
        final prev = pts[(i + 3) % 4];
        final dn = _norm(next, curr, cornerLen);
        final dp = _norm(prev, curr, cornerLen);
        canvas.drawLine(curr, Offset(curr.dx + dn.dx, curr.dy + dn.dy), cp);
        canvas.drawLine(curr, Offset(curr.dx + dp.dx, curr.dy + dp.dy), cp);
      }
    } else {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = _color.withValues(alpha: 0.15),
      );
      canvas.drawRect(
        Rect.fromLTWH(3, 3, size.width - 6, size.height - 6),
        Paint()
          ..color = _color.withValues(alpha: 0.7)
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke,
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
