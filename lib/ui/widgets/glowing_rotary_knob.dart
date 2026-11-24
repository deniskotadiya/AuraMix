import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_theme.dart';

class _ImmediateKnobGestureRecognizer extends OneSequenceGestureRecognizer {
  ValueChanged<Offset>? onTouchDown;
  ValueChanged<Offset>? onTouchUpdate;
  VoidCallback? onTouchUp;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer, event.transform);
    resolve(GestureDisposition.accepted); // Immediately win gesture arena to prevent SingleChildScrollView from scrolling
    onTouchDown?.call(event.localPosition);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      onTouchUpdate?.call(event.localPosition);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      onTouchUp?.call();
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  String get debugDescription => 'ImmediateKnobGestureRecognizer';

  @override
  void didStopTrackingLastPointer(int pointer) {}
}

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
  static const double _knobSize = 84.0;
  static const Offset _knobCenter = Offset(_knobSize / 2, _knobSize / 2);

  bool _isInteracting = false;
  double _lastVibratedStep = -1;

  void _triggerHaptic(double val) {
    final step = (val * 20).roundToDouble(); // Every 5%
    if (step != _lastVibratedStep) {
      _lastVibratedStep = step;
      HapticFeedback.selectionClick();
    }
  }

  void _updateValueFromPosition(Offset localPos) {
    final dx = localPos.dx - _knobCenter.dx;
    final dy = localPos.dy - _knobCenter.dy;
    final distance = sqrt(dx * dx + dy * dy);

    // If extremely close to center point, ignore to avoid angular erratic jumps
    if (distance < 8) return;

    var angle = atan2(dy, dx);
    if (angle < 0) {
      angle += 2 * pi;
    }

    const startAngle = 135 * (pi / 180); // 3 * pi / 4
    const sweepAngle = 270 * (pi / 180); // 3 * pi / 2
    const deadZoneStart = 45 * (pi / 180); // pi / 4
    const deadZoneEnd = 135 * (pi / 180); // 3 * pi / 4

    double newVal;
    if (angle > deadZoneStart && angle < deadZoneEnd) {
      // Finger is inside the bottom dead zone gap:
      // Snap to 1.0 if closer to 45° (right end) or 0.0 if closer to 135° (left end)
      newVal = widget.value > 0.5 ? 1.0 : 0.0;
    } else {
      double sweepOffset;
      if (angle >= startAngle) {
        sweepOffset = angle - startAngle;
      } else {
        sweepOffset = (angle + 2 * pi) - startAngle;
      }
      newVal = (sweepOffset / sweepAngle).clamp(0.0, 1.0);

      // Prevent sudden jump across bottom gap when dragging fast across boundary
      if (widget.value < 0.25 && newVal > 0.75) {
        newVal = 0.0;
      } else if (widget.value > 0.75 && newVal < 0.25) {
        newVal = 1.0;
      }
    }

    if ((newVal - widget.value).abs() > 0.001) {
      widget.onChanged(newVal);
      _triggerHaptic(newVal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.isPremium && !widget.isUnlocked;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RawGestureDetector(
          behavior: HitTestBehavior.opaque,
          gestures: <Type, GestureRecognizerFactory>{
            _ImmediateKnobGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<_ImmediateKnobGestureRecognizer>(
              () => _ImmediateKnobGestureRecognizer(),
              (_ImmediateKnobGestureRecognizer instance) {
                instance
                  ..onTouchDown = (pos) {
                    if (isLocked) {
                      widget.onLockedTap?.call();
                    } else {
                      setState(() => _isInteracting = true);
                      _updateValueFromPosition(pos);
                    }
                  }
                  ..onTouchUpdate = (pos) {
                    if (!isLocked) {
                      _updateValueFromPosition(pos);
                    }
                  }
                  ..onTouchUp = () {
                    if (!isLocked) {
                      setState(() => _isInteracting = false);
                    }
                  };
              },
            ),
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(_knobSize, _knobSize),
                painter: _KnobPainter(
                  value: widget.value,
                  color: isLocked ? Colors.grey : widget.activeColor,
                  isLocked: isLocked,
                  isInteracting: _isInteracting,
                ),
              ),
              // Center Inner Disc
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF131524),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(200),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                    if (!isLocked)
                      BoxShadow(
                        color: widget.activeColor.withAlpha(_isInteracting ? 90 : 50),
                        blurRadius: _isInteracting ? 14 : 10,
                        spreadRadius: _isInteracting ? 2 : 1,
                      ),
                  ],
                  border: Border.all(
                    color: isLocked
                        ? Colors.white.withAlpha(20)
                        : (_isInteracting
                            ? widget.activeColor
                            : widget.activeColor.withAlpha(90)),
                    width: _isInteracting ? 2.0 : 1.5,
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
                            color: _isInteracting ? Colors.white : widget.activeColor,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: isLocked ? widget.onLockedTap : null,
          child: Row(
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
        ),
      ],
    );
  }
}

class _KnobPainter extends CustomPainter {
  final double value;
  final Color color;
  final bool isLocked;
  final bool isInteracting;

  _KnobPainter({
    required this.value,
    required this.color,
    required this.isLocked,
    this.isInteracting = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;

    const startAngle = 135 * (pi / 180);
    const sweepTotalAngle = 270 * (pi / 180);

    // Background track arc (full 270° path)
    final bgPaint = Paint()
      ..color = Colors.white.withAlpha(30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotalAngle,
      false,
      bgPaint,
    );

    // Min & Max anchor tick dots at ends of the circular track
    final minDotX = center.dx + radius * cos(startAngle);
    final minDotY = center.dy + radius * sin(startAngle);
    final maxDotX = center.dx + radius * cos(startAngle + sweepTotalAngle);
    final maxDotY = center.dy + radius * sin(startAngle + sweepTotalAngle);
    final anchorPaint = Paint()..color = Colors.white.withAlpha(45);
    canvas.drawCircle(Offset(minDotX, minDotY), 2.5, anchorPaint);
    canvas.drawCircle(Offset(maxDotX, maxDotY), 2.5, anchorPaint);

    // Active illuminated arc
    final activeSweep = sweepTotalAngle * value;
    if (activeSweep > 0.005) {
      // Soft neon bloom behind the active arc
      if (!isLocked) {
        final glowPaint = Paint()
          ..color = color.withAlpha(isInteracting ? 110 : 70)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isInteracting ? 10.0 : 8.0
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          activeSweep,
          false,
          glowPaint,
        );
      }

      // Foreground crisp active arc
      final activePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        activeSweep,
        false,
        activePaint,
      );

      // Pointer indicator dot at current head of arc
      final currentAngle = startAngle + activeSweep;
      final dotX = center.dx + radius * cos(currentAngle);
      final dotY = center.dy + radius * sin(currentAngle);

      // Outer glow for pointer dot
      if (!isLocked) {
        final dotGlow = Paint()
          ..color = color.withAlpha(150)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset(dotX, dotY), 6.5, dotGlow);
      }

      // Core white pointer dot
      final dotPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(dotX, dotY), 4.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _KnobPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.color != color ||
      oldDelegate.isLocked != isLocked ||
      oldDelegate.isInteracting != isInteracting;
}
