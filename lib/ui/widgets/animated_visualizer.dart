import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/audio_player_service.dart';

class AnimatedVisualizer extends StatefulWidget {
  final double height;
  final bool showVUMeter; // Kept for backwards compatibility, CH-L/R removed

  const AnimatedVisualizer({
    super.key,
    this.height = 54,
    this.showVUMeter = false,
  });

  @override
  State<AnimatedVisualizer> createState() => _AnimatedVisualizerState();
}

class _AnimatedVisualizerState extends State<AnimatedVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _waveController,
        AudioPlayerService.instance,
      ]),
      builder: (context, _) {
        final isPlaying = AudioPlayerService.instance.isPlaying;
        final phase = _waveController.value * 2 * pi;

        return Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0C0E1E).withAlpha(140),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(12), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CustomPaint(
              painter: _RelaxingFluidWavePainter(
                phase: phase,
                isPlaying: isPlaying,
              ),
              size: Size(double.infinity, widget.height),
            ),
          ),
        );
      },
    );
  }
}

class _RelaxingFluidWavePainter extends CustomPainter {
  final double phase;
  final bool isPlaying;

  _RelaxingFluidWavePainter({
    required this.phase,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final width = size.width;

    final primaryAmplitude = isPlaying ? size.height * 0.28 : size.height * 0.08;
    final secondaryAmplitude = isPlaying ? size.height * 0.18 : size.height * 0.05;

    // Secondary ambient background wave (Violet/Cyan soft layer)
    final path2 = Path();
    path2.moveTo(0, centerY);
    for (double x = 0; x <= width; x += 3) {
      final normalizedX = x / width;
      final y = centerY +
          sin(normalizedX * 2 * pi * 1.5 - phase * 0.8) *
              secondaryAmplitude *
              sin(normalizedX * pi); // Soft taper at ends
      path2.lineTo(x, y);
    }

    final paint2 = Paint()
      ..color = AppTheme.neonPurple.withAlpha(60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path2, paint2);

    // Primary foreground relaxing sine wave (Cyan glow)
    final path1 = Path();
    path1.moveTo(0, centerY);
    for (double x = 0; x <= width; x += 3) {
      final normalizedX = x / width;
      final y = centerY +
          sin(normalizedX * 2 * pi * 2.0 + phase) *
              primaryAmplitude *
              sin(normalizedX * pi); // Soft taper at ends
      path1.lineTo(x, y);
    }

    // Glow under primary wave
    final glowPaint = Paint()
      ..color = AppTheme.neonCyan.withAlpha(isPlaying ? 85 : 35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawPath(path1, glowPaint);

    // Crisp primary wave
    final paint1 = Paint()
      ..shader = const LinearGradient(
        colors: [
          AppTheme.neonCyan,
          AppTheme.electricBlue,
          AppTheme.neonPurple,
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path1, paint1);

    // Gentle center node dot
    final centerPulse = isPlaying ? (sin(phase * 2) * 1.5 + 4.0) : 3.0;
    final dotPaint = Paint()..color = AppTheme.neonCyan;
    final dotGlow = Paint()
      ..color = AppTheme.neonCyan.withAlpha(120)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final dotY = centerY + sin(0.5 * 2 * pi * 2.0 + phase) * primaryAmplitude;
    canvas.drawCircle(Offset(width / 2, dotY), centerPulse + 2, dotGlow);
    canvas.drawCircle(Offset(width / 2, dotY), centerPulse, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _RelaxingFluidWavePainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.isPlaying != isPlaying;
}
