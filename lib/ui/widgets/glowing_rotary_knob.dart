import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class GlowingRotaryKnob extends StatefulWidget {
  final double value; // 0.0 to 1.0
  final ValueChanged<double> onChanged;
  final String label;
  final String displayValue;
  final Color activeColor;
  final bool isPremium;
  final bool isUnlocked;
  final VoidCallback? onLockedTap;

  const GlowingRotaryKnob({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    required this.displayValue,
    this.activeColor = AppTheme.neonCyan,
    this.isPremium = false,
    this.isUnlocked = true,
    this.onLockedTap,
  });

  @override
  State<GlowingRotaryKnob> createState() => _GlowingRotaryKnobState();
}

class _GlowingRotaryKnobState extends State<GlowingRotaryKnob> {
  double _dragStartY = 0;
  double _startValue = 0;

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.isPremium && !widget.isUnlocked;

    return GestureDetector(
      onTap: isLocked ? widget.onLockedTap : null,
      onVerticalDragStart: isLocked ? null : (details) {
        _dragStartY = details.localPosition.dy;
        _startValue = widget.value;
      },
      onVerticalDragUpdate: isLocked ? null : (details) {
        final delta = (_dragStartY - details.localPosition.dy) / 120.0;
        final newVal = (_startValue + delta).clamp(0.0, 1.0);
        widget.onChanged(newVal);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(82, 82),
                painter: _KnobPainter(
                  value: widget.value,
                  color: isLocked ? Colors.grey : widget.activeColor,
                  isLocked: isLocked,
                ),
              ),
              // Center Inner Disc
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF131524),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(180),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                    if (!isLocked)
                      BoxShadow(
                        color: widget.activeColor.withAlpha(50),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                  ],
                  border: Border.all(
                    color: isLocked
                        ? Colors.white.withAlpha(20)
                        : widget.activeColor.withAlpha(80),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: isLocked
                      ? const Icon(Icons.lock_rounded, size: 20, color: AppTheme.carAmber)
                      : Text(
                          widget.displayValue,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: widget.activeColor,
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isPremium) ...[
                Icon(
                  Icons.star_rounded,
                  size: 13,
                  color: widget.isUnlocked ? AppTheme.carNeonGreen : AppTheme.carAmber,
                ),
                const SizedBox(width: 3),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isLocked ? Colors.white54 : Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KnobPainter extends CustomPainter {
  final double value;
  final Color color;
  final bool isLocked;

  _KnobPainter({
    required this.value,
    required this.color,
    required this.isLocked,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    const startAngle = 135 * (pi / 180);
    const sweepTotalAngle = 270 * (pi / 180);

    // Background track arc
    final bgPaint = Paint()
      ..color = Colors.white.withAlpha(25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotalAngle,
      false,
      bgPaint,
    );

    // Active illuminated arc
    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final activeSweep = sweepTotalAngle * value;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      activeSweep,
      false,
      activePaint,
    );

    // Pointer Dot on outer ring
    final currentAngle = startAngle + activeSweep;
    final dotX = center.dx + radius * cos(currentAngle);
    final dotY = center.dy + radius * sin(currentAngle);

    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(dotX, dotY), 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _KnobPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color || oldDelegate.isLocked != isLocked;
}
