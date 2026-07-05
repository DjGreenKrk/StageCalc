import 'package:flutter/material.dart';

import '../../app/theme/greencrew_colors.dart';

class StageCalcMark extends StatelessWidget {
  const StageCalcMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _StageCalcMarkPainter(),
    );
  }
}

class _StageCalcMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final hexPaint = Paint()
      ..color = GreenCrewColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.075
      ..strokeJoin = StrokeJoin.round;

    final boltPaint = Paint()
      ..color = GreenCrewColors.primary
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final hex = Path()
      ..moveTo(w * 0.50, h * 0.06)
      ..lineTo(w * 0.86, h * 0.27)
      ..lineTo(w * 0.86, h * 0.73)
      ..lineTo(w * 0.50, h * 0.94)
      ..lineTo(w * 0.14, h * 0.73)
      ..lineTo(w * 0.14, h * 0.27)
      ..close();

    final bolt = Path()
      ..moveTo(w * 0.56, h * 0.18)
      ..lineTo(w * 0.34, h * 0.54)
      ..lineTo(w * 0.49, h * 0.54)
      ..lineTo(w * 0.42, h * 0.82)
      ..lineTo(w * 0.68, h * 0.43)
      ..lineTo(w * 0.53, h * 0.43)
      ..close();

    canvas.drawPath(hex, hexPaint);
    canvas.drawPath(bolt, boltPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
