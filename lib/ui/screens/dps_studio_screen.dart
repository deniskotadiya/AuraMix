import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/dps_engine.dart';
import '../../core/auth_service.dart';
import '../../core/monetization_config.dart';
import '../../core/audio_player_service.dart';
import '../widgets/glowing_rotary_knob.dart';
import '../widgets/premium_unlock_dialog.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/acoustic_profile_selector.dart';
import 'create_preset_screen.dart';

class DPSStudioScreen extends StatelessWidget {
  const DPSStudioScreen({super.key});

  void _handleLockedControlTap(
    BuildContext context, {
    required String controlKey,
    required String controlName,
    required String description,
    required VoidCallback onUnlocked,
  }) {
    PremiumUnlockDialog.show(
      context: context,
      controlKey: controlKey,
      controlName: controlName,
      description: description,
      onUnlocked: onUnlocked,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        DPSEngine.instance,
        AuthService.instance.currentUserNotifier,
      ]),
      builder: (context, _) {
        final dps = DPSEngine.instance;
        final active = dps.activePreset;

        final isTubeUnlocked = AuthService.instance.isControlUnlocked(MonetizationConfig.controlTubeWarmth);
        final isCompressorUnlocked = AuthService.instance.isControlUnlocked(MonetizationConfig.controlCompressor);
        final isSurroundUnlocked = AuthService.instance.isControlUnlocked(MonetizationConfig.controlSurround3D);

        return Scaffold(
          appBar: AppBar(
            title: const Text('DPS Sound Studio'),
            actions: [
              IconButton(
                icon: const Icon(Icons.bookmark_add_outlined, color: AppTheme.neonCyan),
                tooltip: 'Save Custom Preset',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CreatePresetScreen(initialPreset: active),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                tooltip: 'Reset EQ',
                onPressed: () => dps.resetEQ(),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Master DPS Switch Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: AppTheme.neonBoxDecoration(
                            glowColor: dps.dpsEnabled ? AppTheme.neonCyan : Colors.transparent,
                            surfaceColor: const Color(0xFF131526),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: dps.dpsEnabled ? AppTheme.carNeonGreen : Colors.redAccent,
                                      boxShadow: [
                                        if (dps.dpsEnabled)
                                          const BoxShadow(
                                            color: AppTheme.carNeonGreen,
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'DIGITAL POWER STATION',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        dps.dpsEnabled ? 'Acoustic processing online' : 'Audio DSP bypassed',
                                        style: const TextStyle(fontSize: 11, color: Colors.white54),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Switch(
                                value: dps.dpsEnabled,
                                activeThumbColor: AppTheme.neonCyan,
                                activeTrackColor: AppTheme.neonCyan.withAlpha(80),
                                onChanged: (val) => dps.toggleDPSEnabled(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Real-time Track Playback Bar
                        ListenableBuilder(
                          listenable: AudioPlayerService.instance,
                          builder: (context, _) {
                            final currentSong = AudioPlayerService.instance.currentSong;
                            final isPlaying = AudioPlayerService.instance.isPlaying;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isPlaying ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
                                    color: AppTheme.neonCyan,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          currentSong?.title ?? 'No Track Loaded',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          currentSong != null
                                              ? 'Tuning "${dps.activePreset.title}" on ${currentSong.artist}'
                                              : 'Play a song from the library to test effects live',
                                          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                                      color: AppTheme.neonCyan,
                                      size: 28,
                                    ),
                                    onPressed: () => AudioPlayerService.instance.togglePlayPause(),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Acoustic Output Device Target (Earbuds, Headphones, Car, Speaker)
                        const AcousticProfileSelector(compact: false),
                        const SizedBox(height: 18),

                        // Preset Selector Carousel
                        const Text(
                          'DPS PRESET PROFILES',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppTheme.neonCyan),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 44,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: DPSEngine.defaultPresets.length,
                            itemBuilder: (ctx, idx) {
                              final p = DPSEngine.defaultPresets[idx];
                              final isSelected = p.id == active.id;

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (p.isPremium) ...[
                                        const Icon(Icons.star_rounded, size: 14, color: AppTheme.carAmber),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(p.title),
                                    ],
                                  ),
                                  selected: isSelected,
                                  selectedColor: AppTheme.neonCyan.withAlpha(50),
                                  backgroundColor: const Color(0xFF14172B),
                                  side: BorderSide(
                                    color: isSelected ? AppTheme.neonCyan : Colors.white12,
                                  ),
                                  onSelected: (sel) {
                                    if (p.isPremium && !AuthService.instance.isControlUnlocked('preset_${p.id}')) {
                                      _handleLockedControlTap(
                                        context,
                                        controlKey: 'preset_${p.id}',
                                        controlName: p.title,
                                        description: '${p.description}\nUnlock this premium DPS profile for 1 session via Ad or get VIP!',
                                        onUnlocked: () => dps.loadPreset(p),
                                      );
                                    } else {
                                      dps.loadPreset(p);
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Rotary DSP Knobs (Bass, 3D Surround, Clarity, Tube Warmth, Compressor)
                        const Text(
                          'ACOUSTIC ENHANCEMENT DIALS',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppTheme.neonCyan),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                          decoration: AppTheme.glassBoxDecoration(radius: 20),
                          child: Wrap(
                            alignment: WrapAlignment.spaceAround,
                            spacing: 12,
                            runSpacing: 16,
                            children: [
                              GlowingRotaryKnob(
                                value: active.bassBoost,
                                onChanged: (v) => dps.setBassBoost(v),
                                label: 'Sub-Bass',
                                displayValue: '${(active.bassBoost * 100).toInt()}%',
                                activeColor: AppTheme.carNeonGreen,
                              ),
                              GlowingRotaryKnob(
                                value: active.surround3D,
                                onChanged: (v) => dps.setSurround3D(v),
                                label: '3D Spatial',
                                displayValue: '${(active.surround3D * 100).toInt()}%',
                                activeColor: AppTheme.neonCyan,
                                isPremium: true,
                                isUnlocked: isSurroundUnlocked,
                                onLockedTap: () => _handleLockedControlTap(
                                  context,
                                  controlKey: MonetizationConfig.controlSurround3D,
                                  controlName: '3D Surround Spatializer',
                                  description: 'Expands stereo width for an immersive concert hall or vehicle cabin soundstage.',
                                  onUnlocked: () => dps.setSurround3D(0.75),
                                ),
                              ),
                              GlowingRotaryKnob(
                                value: active.clarity,
                                onChanged: (v) => dps.setClarity(v),
                                label: 'Vocal Clarity',
                                displayValue: '${(active.clarity * 100).toInt()}%',
                                activeColor: AppTheme.neonPurple,
                              ),
                              GlowingRotaryKnob(
                                value: active.tubeWarmth,
                                onChanged: (v) => dps.setTubeWarmth(v),
                                label: 'Tube Warmth',
                                displayValue: '${(active.tubeWarmth * 100).toInt()}%',
                                activeColor: AppTheme.carAmber,
                                isPremium: true,
                                isUnlocked: isTubeUnlocked,
                                onLockedTap: () => _handleLockedControlTap(
                                  context,
                                  controlKey: MonetizationConfig.controlTubeWarmth,
                                  controlName: 'Analog Vacuum Tube Warmth',
                                  description: 'Emulates vintage analog tube amplifier harmonics, adding rich warmth and punch.',
                                  onUnlocked: () => dps.setTubeWarmth(0.65),
                                ),
                              ),
                              GlowingRotaryKnob(
                                value: active.compressor,
                                onChanged: (v) => dps.setCompressor(v),
                                label: 'Compressor',
                                displayValue: '${(active.compressor * 100).toInt()}%',
                                activeColor: AppTheme.neonPink,
                                isPremium: true,
                                isUnlocked: isCompressorUnlocked,
                                onLockedTap: () => _handleLockedControlTap(
                                  context,
                                  controlKey: MonetizationConfig.controlCompressor,
                                  controlName: 'Dynamic Studio Compressor',
                                  description: 'Evens out dynamic volume peaks, providing loud, punchy, road-noise-resistant playback.',
                                  onUnlocked: () => dps.setCompressor(0.60),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Stem & Instrument Sound Isolation (Vocals, Music, Beat, Air)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'STEM & INSTRUMENT EQUALIZATION',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppTheme.neonCyan),
                            ),
                            TextButton(
                              onPressed: () => dps.resetStems(),
                              child: const Text('Reset All', style: TextStyle(color: Colors.white54, fontSize: 11)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: AppTheme.glassBoxDecoration(radius: 16),
                          child: Column(
                            children: [
                              _buildStemRow(
                                icon: Icons.record_voice_over_rounded,
                                label: 'Words & Vocals',
                                value: active.vocalGain,
                                color: AppTheme.neonPurple,
                                onChanged: (v) => dps.setVocalGain(v),
                              ),
                              const Divider(color: Colors.white10, height: 16),
                              _buildStemRow(
                                icon: Icons.music_note_rounded,
                                label: 'Music & Harmony',
                                value: active.musicGain,
                                color: AppTheme.neonCyan,
                                onChanged: (v) => dps.setMusicGain(v),
                              ),
                              const Divider(color: Colors.white10, height: 16),
                              _buildStemRow(
                                icon: Icons.album_rounded,
                                label: 'Bass & Rhythm / Beat',
                                value: active.bassGain,
                                color: AppTheme.carNeonGreen,
                                onChanged: (v) => dps.setBassGain(v),
                              ),
                              const Divider(color: Colors.white10, height: 16),
                              _buildStemRow(
                                icon: Icons.auto_awesome_rounded,
                                label: 'Treble & Shimmer',
                                value: active.trebleGain,
                                color: AppTheme.carAmber,
                                onChanged: (v) => dps.setTrebleGain(v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        // 10-Band Graphic Equalizer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '10-BAND GRAPHIC EQUALIZER (±12 dB)',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppTheme.neonCyan),
                            ),
                            TextButton(
                              onPressed: () => dps.resetEQ(),
                              child: const Text('Flat 0 dB', style: TextStyle(color: Colors.white54, fontSize: 11)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 180,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          decoration: AppTheme.glassBoxDecoration(radius: 16),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: List.generate(10, (idx) {
                                final freq = DPSEngine.eqFrequencies[idx];
                                final gain = active.eqBands[idx];

                                return Container(
                                  width: 44,
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: Column(
                                    children: [
                                      Text(
                                        '${gain >= 0 ? "+" : ""}${gain.toStringAsFixed(1)}',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: gain > 0 ? AppTheme.neonCyan : (gain < 0 ? AppTheme.neonPink : Colors.white38),
                                        ),
                                      ),
                                      Expanded(
                                        child: RotatedBox(
                                          quarterTurns: 3,
                                          child: SliderTheme(
                                            data: SliderTheme.of(context).copyWith(
                                              trackHeight: 3,
                                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                              activeTrackColor: AppTheme.neonCyan,
                                              inactiveTrackColor: Colors.white12,
                                            ),
                                            child: Slider(
                                              value: gain,
                                              min: -12.0,
                                              max: 12.0,
                                              onChanged: (val) => dps.updateBand(idx, val),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        freq,
                                        style: const TextStyle(fontSize: 9, color: Colors.white60),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Acoustic Reverb & Tempo Section
                        const Text(
                          'ACOUSTIC ENVIRONMENT & TEMPO',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppTheme.neonCyan),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: AppTheme.glassBoxDecoration(radius: 16),
                          child: Column(
                            children: [
                              // Reverb Space
                              Row(
                                children: [
                                  const Icon(Icons.surround_sound_rounded, color: AppTheme.neonCyan, size: 20),
                                  const SizedBox(width: 8),
                                  const Text('Acoustic Reverb Space:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const Spacer(),
                                  DropdownButton<String>(
                                    value: active.reverbType,
                                    dropdownColor: const Color(0xFF14172B),
                                    underline: const SizedBox(),
                                    items: ['Off', 'Studio', 'Club', 'Arena', 'Cathedral'].map((t) {
                                      return DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)));
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        if (val == 'Cathedral' && !AuthService.instance.isControlUnlocked(MonetizationConfig.controlReverbCathedral)) {
                                          _handleLockedControlTap(
                                            context,
                                            controlKey: MonetizationConfig.controlReverbCathedral,
                                            controlName: 'Cathedral Acoustic Chamber',
                                            description: 'Massive atmospheric reverberation with extended decay.',
                                            onUnlocked: () => dps.setReverb(val, active.reverbMix),
                                          );
                                        } else {
                                          dps.setReverb(val, active.reverbMix);
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.white10),
                              // Speed / Tempo
                              Row(
                                children: [
                                  const Icon(Icons.speed, color: AppTheme.carAmber, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Playback Speed: ${active.speed.toStringAsFixed(2)}x',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () => dps.setSpeed(1.0),
                                    child: const Text('1.0x', style: TextStyle(fontSize: 11, color: Colors.white54)),
                                  ),
                                ],
                              ),
                              Slider(
                                value: active.speed,
                                min: 0.5,
                                max: 2.0,
                                onChanged: (v) => dps.setSpeed(v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                const BannerAdWidget(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStemRow({
    required IconData icon,
    required String label,
    required double value,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        SizedBox(
          width: 130,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${value >= 0 ? "+" : ""}${value.toStringAsFixed(1)} dB',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              activeTrackColor: color,
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: value,
              min: -12.0,
              max: 12.0,
              divisions: 48,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
