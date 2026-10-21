import 'dart:math' as math;
import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AuvorynLogo extends StatelessWidget {
  const AuvorynLogo({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 28,
          height: 28,
          child: CustomPaint(painter: _AuvorynMarkPainter()),
        ),
        if (!compact) ...[
          const SizedBox(width: 9),
          const Text(
            'auvoryn',
            style: TextStyle(
              color: AuvorynColors.ivory,
              fontSize: 20,
              letterSpacing: -0.85,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _AuvorynMarkPainter extends CustomPainter {
  const _AuvorynMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final ring = Paint()
      ..color = AuvorynColors.champagne
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width * .41),
      -math.pi * .28,
      math.pi * 1.73,
      false,
      ring,
    );

    final groove = Path()
      ..moveTo(size.width * .26, size.height * .40)
      ..cubicTo(
        size.width * .36,
        size.height * .72,
        size.width * .50,
        size.height * .76,
        size.width * .57,
        size.height * .48,
      )
      ..quadraticBezierTo(
        size.width * .64,
        size.height * .21,
        size.width * .76,
        size.height * .35,
      );
    canvas.drawPath(
      groove,
      Paint()
        ..color = AuvorynColors.champagne
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _AuvorynMarkPainter oldDelegate) => false;
}
