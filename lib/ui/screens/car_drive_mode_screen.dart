import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/audio_player_service.dart';
import '../../core/dps_engine.dart';
import '../widgets/animated_visualizer.dart';

class CarDriveModeScreen extends StatefulWidget {
  const CarDriveModeScreen({super.key});

  @override
  State<CarDriveModeScreen> createState() => _CarDriveModeScreenState();
}

class _CarDriveModeScreenState extends State<CarDriveModeScreen> {
  Timer? _clockTimer;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    final hour12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    if (mounted) {
      setState(() => _currentTime = '$hour12:$minute $period');
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _setCarAcousticMode(String mode) {
    final dps = DPSEngine.instance;
    switch (mode) {
      case 'Highway Roar':
        dps.setBassBoost(0.90);
        dps.setCompressor(0.80);
        dps.setClarity(0.70);
        dps.setSurround3D(0.65);
        break;
      case 'Night Cabin':
        dps.setBassBoost(0.65);
        dps.setTubeWarmth(0.85);
        dps.setSurround3D(0.80);
        dps.setClarity(0.75);
        break;
      case 'City Cruiser':
        dps.setBassBoost(0.70);
        dps.setClarity(0.85);
        dps.setSurround3D(0.50);
        dps.setCompressor(0.40);
        break;
      case 'Subwoofer Max':
        dps.setBassBoost(1.0);
        dps.setCompressor(0.85);
        dps.setSurround3D(0.40);
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF162B44),
        content: Text('🚗 Car Acoustic Mode: $mode Active'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AudioPlayerService.instance,
      builder: (context, _) {
        final currentSong = AudioPlayerService.instance.currentSong;
        final isPlaying = AudioPlayerService.instance.isPlaying;

        return Scaffold(
          backgroundColor: const Color(0xFF07080F),
          body: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.2),
                radius: 1.2,
                colors: [
                  Color(0xFF131733),
                  Color(0xFF090A14),
                  Color(0xFF04050A),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  children: [
                    // Top Car HUD Status Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.speed_rounded, color: AppTheme.carAmber, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              _currentTime,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.carNeonGreen.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.carNeonGreen.withAlpha(90)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.directions_car, size: 14, color: AppTheme.carNeonGreen),
                              SizedBox(width: 4),
                              Text(
                                'CAR COCKPIT HUD',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: AppTheme.carNeonGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_fullscreen_rounded, color: Colors.white70),
                          tooltip: 'Exit Car HUD',
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Big Track Information
                    Text(
                      currentSong?.title ?? 'No Track Playing',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currentSong?.artist ?? 'AuraMix Cockpit Audio',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.neonCyan,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),

                    // Dynamic Spectrum Visualizer
                    const AnimatedVisualizer(height: 50, showVUMeter: false),
                    const Spacer(),

                    // Quick Car Acoustic Tuning Selector
                    const Text(
                      'CAR CABIN ACOUSTIC PRESETS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _CarPresetPill(
                            title: 'Highway Roar',
                            icon: Icons.alt_route_rounded,
                            onTap: () => _setCarAcousticMode('Highway Roar'),
                          ),
                          _CarPresetPill(
                            title: 'Night Cabin',
                            icon: Icons.nightlife_rounded,
                            onTap: () => _setCarAcousticMode('Night Cabin'),
                          ),
                          _CarPresetPill(
                            title: 'City Cruiser',
                            icon: Icons.location_city_rounded,
                            onTap: () => _setCarAcousticMode('City Cruiser'),
                          ),
                          _CarPresetPill(
                            title: 'Subwoofer Max',
                            icon: Icons.surround_sound_rounded,
                            onTap: () => _setCarAcousticMode('Subwoofer Max'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Giant Driving-Safe Touch Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Giant Previous
                        IconButton(
                          iconSize: 52,
                          icon: const Icon(Icons.skip_previous_rounded, color: Colors.white),
                          onPressed: () => AudioPlayerService.instance.skipToPrevious(),
                        ),

                        // Giant Glowing Play/Pause
                        GestureDetector(
                          onTap: () => AudioPlayerService.instance.togglePlayPause(),
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppTheme.cyanPurpleGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.neonCyan.withAlpha(150),
                                  blurRadius: 28,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              size: 52,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        // Giant Next
                        IconButton(
                          iconSize: 52,
                          icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
                          onPressed: () => AudioPlayerService.instance.skipToNext(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CarPresetPill extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _CarPresetPill({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF14192E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withAlpha(20)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppTheme.neonCyan),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
