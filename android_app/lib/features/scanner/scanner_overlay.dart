import 'package:flutter/material.dart';

class ScannerOverlay extends StatelessWidget {
  const ScannerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScannerOverlayPainter(),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scanAreaSize = size.width * 0.7;
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2;

    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5);

    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRect(Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize))
        ..fillType = PathFillType.evenOdd,
      backgroundPaint,
    );

    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final double cornerLength = 30;

    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLength, top),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left, top + cornerLength),
      borderPaint,
    );

    canvas.drawLine(
      Offset(left + scanAreaSize, top),
      Offset(left + scanAreaSize - cornerLength, top),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top),
      Offset(left + scanAreaSize, top + cornerLength),
      borderPaint,
    );

    canvas.drawLine(
      Offset(left, top + scanAreaSize),
      Offset(left + cornerLength, top + scanAreaSize),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left, top + scanAreaSize),
      Offset(left, top + scanAreaSize - cornerLength),
      borderPaint,
    );

    canvas.drawLine(
      Offset(left + scanAreaSize, top + scanAreaSize),
      Offset(left + scanAreaSize - cornerLength, top + scanAreaSize),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top + scanAreaSize),
      Offset(left + scanAreaSize, top + scanAreaSize - cornerLength),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
