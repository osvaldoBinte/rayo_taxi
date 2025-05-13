// emergency_button.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import './emergency_controller.dart';

class ProgressArcPainter extends CustomPainter {
  final double progress;
  final bool isPressed;

  ProgressArcPainter({
    required this.progress,
    required this.isPressed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isPressed) return;

    final double strokeWidth = 4.0;
    final double padding = strokeWidth / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - padding * 2) / 2;

    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final progressPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final startAngle = -90.0 * (3.14159 / 180.0);
    final sweepAngle = 360.0 * (3.14159 / 180.0) * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ProgressArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isPressed != isPressed;
  }
}