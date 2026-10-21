import 'dart:math' as math;

import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// A locally rendered record cover. It does not pretend to be embedded album art.
/// The animation follows the real player state and stops when motion is reduced.
class VinylArtwork extends StatefulWidget {
  const VinylArtwork({
    required this.title,
    required this.playing,
    this.size = 280,
    this.compact = false,
    super.key,
  });

  final String title;
  final bool playing;
  final double size;
  final bool compact;

  @override
  State<VinylArtwork> createState() => _VinylArtworkState();
}

class _VinylArtworkState extends State<VinylArtwork>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant VinylArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playing != widget.playing) _syncAnimation();
  }

  void _syncAnimation() {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (widget.playing && !reduceMotion) {
      _rotation.repeat();
    } else {
      _rotation.stop(canceled: false);
    }
  }

  @override
  void dispose() {
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final side = widget.size;
    return Semantics(
      label: widget.playing ? 'Vinyl record playing' : 'Vinyl record paused',
      image: true,
      child: RepaintBoundary(
        child: SizedBox(
          width: side,
          height: side,
          child: Stack(
            alignment: Alignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .48),
                      blurRadius: side * .12,
                      offset: Offset(0, side * .07),
                    ),
                  ],
                ),
                child: SizedBox.square(dimension: side),
              ),
              AnimatedBuilder(
                animation: _rotation,
                builder: (context, child) => Transform.rotate(
                  angle: _rotation.value * math.pi * 2,
                  child: child,
                ),
                child: CustomPaint(
                  size: Size.square(side),
                  painter: _RecordPainter(
                    label: widget.title,
                    compact: widget.compact,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordPainter extends CustomPainter {
  const _RecordPainter({required this.label, required this.compact});
  final String label;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final disc = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(center, radius, Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFF15171D), Color(0xFF30343B), Color(0xFF101116),
          Color(0xFF23262B), Color(0xFF44434A), Color(0xFF15171D),
        ],
      ).createShader(disc));

    final groovePaint = Paint()
      ..color = const Color(0x40B6B7C0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.45, radius * .0035);
    for (var i = 0; i < 19; i++) {
      canvas.drawCircle(center, radius * (.39 + i * .031), groovePaint);
    }

    canvas.drawCircle(center, radius * .35, Paint()
      ..shader = const RadialGradient(colors: [
        Color(0xFFE6CBA7), AuvorynColors.champagne, Color(0xFF8E6950),
      ]).createShader(Rect.fromCircle(center: center, radius: radius * .36)));
    canvas.drawCircle(center, radius * .29, Paint()
      ..color = const Color(0xFF141820));
    canvas.drawCircle(center, radius * .267, Paint()
      ..color = const Color(0xFF24272F));

    if (!compact) {
      final painter = TextPainter(
        text: TextSpan(
          text: label.toUpperCase(),
          style: TextStyle(
            color: AuvorynColors.ivory,
            fontSize: math.max(8.0, radius * .075),
            fontWeight: FontWeight.w700,
            letterSpacing: .7,
          ),
        ),
        maxLines: 1,
        ellipsis: '…',
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: radius * .46);
      painter.paint(canvas, Offset(center.dx - painter.width / 2,
          center.dy - painter.height / 2));
    }
    canvas.drawCircle(center, radius * .027, Paint()
      ..color = AuvorynColors.mist);
    canvas.drawCircle(center, radius * .012, Paint()
      ..color = AuvorynColors.ink);
  }

  @override
  bool shouldRepaint(covariant _RecordPainter oldDelegate) =>
      oldDelegate.label != label || oldDelegate.compact != compact;
}
