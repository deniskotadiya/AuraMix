import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/audio_player_service.dart';

class AnimatedVisualizer extends StatelessWidget {
  final double height;
  final bool showVUMeter;

  const AnimatedVisualizer({
    super.key,
    this.height = 70,
    this.showVUMeter = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showVUMeter) ...[
          const DualAnalogVUMeter(),
          const SizedBox(height: 12),
        ],
        ValueListenableBuilder<List<double>>(
          valueListenable: AudioPlayerService.instance.visualizerBands,
          builder: (context, bands, _) {
            return SizedBox(
              height: height,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(bands.length, (index) {
                  final amp = bands[index];
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 60),
                    curve: Curves.easeOutQuad,
                    width: (MediaQuery.of(context).size.width - 64) / (bands.length * 1.45),
                    height: (amp * height).clamp(4.0, height),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppTheme.neonCyan,
                          if (amp > 0.5) AppTheme.neonPurple else AppTheme.electricBlue,
                          if (amp > 0.8) AppTheme.neonPink else AppTheme.neonPurple,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.neonCyan.withAlpha((amp * 90).toInt()),
                          blurRadius: 6,
                          spreadRadius: 0.5,
                        ),
                      ],
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Dual Analog VU Meter (L & R Channels) styled like classic high-end car stereo gauges
class DualAnalogVUMeter extends StatelessWidget {
  const DualAnalogVUMeter({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ValueListenableBuilder<double>(
            valueListenable: AudioPlayerService.instance.vuMeterLeft,
            builder: (context, value, _) {
              return _VUMeterGauge(channel: 'CH-L', value: value);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ValueListenableBuilder<double>(
            valueListenable: AudioPlayerService.instance.vuMeterRight,
            builder: (context, value, _) {
              return _VUMeterGauge(channel: 'CH-R', value: value);
            },
          ),
        ),
      ],
    );
  }
}

class _VUMeterGauge extends StatelessWidget {
  final String channel;
  final double value;

  const _VUMeterGauge({
    required this.channel,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF101222),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(120),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Text(
              channel,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.neonCyan,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: value > 0.85 ? AppTheme.neonPink : Colors.white60,
              ),
            ),
          ),
          Positioned.fill(
            top: 14,
            child: CustomPaint(
              painter: _VUNeedlePainter(value: value),
            ),
          ),
        ],
      ),
    );
  }
}

class _VUNeedlePainter extends CustomPainter {
  final double value; // 0.0 to 1.0

  _VUNeedlePainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final pivot = Offset(size.width / 2, size.height + 15);
    final needleLength = size.height + 10;

    // Needle sweep: -50 deg to +50 deg
    final angle = (-50 + (value * 100)) * (pi / 180);

    // Scale tick marks
    final scalePaint = Paint()
      ..color = Colors.white.withAlpha(40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i <= 8; i++) {
      final tickAngle = (-50 + (i * 12.5)) * (pi / 180);
      final rInner = needleLength - 10;
      final rOuter = needleLength - 4;
      final p1 = Offset(pivot.dx + rInner * sin(tickAngle), pivot.dy - rInner * cos(tickAngle));
      final p2 = Offset(pivot.dx + rOuter * sin(tickAngle), pivot.dy - rOuter * cos(tickAngle));

      if (i >= 6) {
        scalePaint.color = AppTheme.neonPink.withAlpha(180);
      } else {
        scalePaint.color = Colors.white.withAlpha(50);
      }
      canvas.drawLine(p1, p2, scalePaint);
    }

    // Needle
    final needleTip = Offset(
      pivot.dx + needleLength * sin(angle),
      pivot.dy - needleLength * cos(angle),
    );

    final needlePaint = Paint()
      ..color = value > 0.85 ? AppTheme.neonPink : AppTheme.carAmber
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(pivot, needleTip, needlePaint);

    // Pivot bulb
    final bulbPaint = Paint()..color = const Color(0xFF282B42);
    canvas.drawCircle(pivot, 5, bulbPaint);
  }

  @override
  bool shouldRepaint(covariant _VUNeedlePainter oldDelegate) => oldDelegate.value != value;
}
