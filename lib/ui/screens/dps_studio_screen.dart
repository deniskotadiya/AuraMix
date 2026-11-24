import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

                        // DJ 3-Band Frequency Kill Isolators & Karaoke Console
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DJ 3-BAND FREQUENCY ISOLATOR',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppTheme.neonCyan),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Pioneer-grade real-time frequency kill-switches',
                                  style: TextStyle(fontSize: 9.5, color: Colors.white38),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () => dps.resetIsolators(),
                              child: const Text('Reset Flat', style: TextStyle(color: Colors.white54, fontSize: 11)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Karaoke Center-Vocal Eliminator Banner
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: active.karaokeEnabled
                                  ? [AppTheme.neonPurple.withAlpha(60), const Color(0xFF1B1633)]
                                  : [const Color(0xFF14172B), const Color(0xFF0F111E)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: active.karaokeEnabled ? AppTheme.neonPurple : Colors.white12,
                              width: active.karaokeEnabled ? 1.5 : 0.8,
                            ),
                            boxShadow: [
                              if (active.karaokeEnabled)
                                BoxShadow(
                                  color: AppTheme.neonPurple.withAlpha(80),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                active.karaokeEnabled ? Icons.mic_off_rounded : Icons.mic_external_on_rounded,
                                color: active.karaokeEnabled ? AppTheme.neonPurple : Colors.white70,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'KARAOKE VOCAL ELIMINATOR',
                                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.8),
                                        ),
                                        if (active.karaokeEnabled) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: AppTheme.neonPurple.withAlpha(40),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text('ACTIVE', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppTheme.neonPurple)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const Text(
                                      'Phase-cancels center-panned lead vocals for sing-along',
                                      style: TextStyle(fontSize: 10, color: Colors.white54),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: active.karaokeEnabled,
                                activeThumbColor: AppTheme.neonPurple,
                                activeTrackColor: AppTheme.neonPurple.withAlpha(90),
                                onChanged: (v) {
                                  HapticFeedback.mediumImpact();
                                  dps.setKaraokeEnabled(v);
                                },
                              ),
                            ],
                          ),
                        ),

                        // Quick DJ Action Presets
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              _buildStemPresetChip(
                                label: 'Club Bass Drop',
                                icon: Icons.speaker_group_rounded,
                                isSelected: active.bassGain >= 8.0 && active.musicGain <= -6.0,
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  dps.setLowGain(10.0);
                                  dps.setMidGain(-12.0);
                                  dps.setHighGain(-8.0);
                                },
                              ),
                              const SizedBox(width: 6),
                              _buildStemPresetChip(
                                label: 'Radio Voice Only',
                                icon: Icons.radio_rounded,
                                isSelected: active.bassGain <= -11.0 && active.trebleGain <= -11.0,
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  dps.setLowGain(-12.0);
                                  dps.setMidGain(3.0);
                                  dps.setHighGain(-12.0);
                                },
                              ),
                              const SizedBox(width: 6),
                              _buildStemPresetChip(
                                label: 'Karaoke Sing-Along',
                                icon: Icons.mic_off_rounded,
                                isSelected: active.karaokeEnabled,
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  dps.setKaraokeEnabled(!active.karaokeEnabled);
                                },
                              ),
                              const SizedBox(width: 6),
                              _buildStemPresetChip(
                                label: 'All Flat (0 dB)',
                                icon: Icons.restart_alt_rounded,
                                isSelected: active.bassGain == 0.0 && active.musicGain == 0.0 && active.trebleGain == 0.0,
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  dps.resetIsolators();
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),

                        // 3-Band DJ Kill Isolator Sliders
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: AppTheme.glassBoxDecoration(radius: 16),
                          child: Column(
                            children: [
                              _buildDJIsolatorRow(
                                icon: Icons.album_rounded,
                                label: 'LOW ISOLATOR (BASS & 808s)',
                                freqRange: 'Sub-bass, Kicks, Bassline (< 300 Hz)',
                                value: active.bassGain,
                                color: AppTheme.carNeonGreen,
                                onChanged: (v) => dps.setLowGain(v),
                                onKillToggle: () {
                                  HapticFeedback.heavyImpact();
                                  dps.toggleLowKill();
                                },
                              ),
                              const Divider(color: Colors.white10, height: 16),
                              _buildDJIsolatorRow(
                                icon: Icons.graphic_eq_rounded,
                                label: 'MID ISOLATOR (VOCALS & GUITARS)',
                                freqRange: 'Lead vocals, Guitars, Keys (300 Hz - 3.5 kHz)',
                                value: active.musicGain,
                                color: AppTheme.neonCyan,
                                onChanged: (v) => dps.setMidGain(v),
                                onKillToggle: () {
                                  HapticFeedback.heavyImpact();
                                  dps.toggleMidKill();
                                },
                              ),
                              const Divider(color: Colors.white10, height: 16),
                              _buildDJIsolatorRow(
                                icon: Icons.auto_awesome_rounded,
                                label: 'HIGH ISOLATOR (TREBLE & AIR)',
                                freqRange: 'Cymbals, Snare snap, Shimmer (> 3.5 kHz)',
                                value: active.trebleGain,
                                color: AppTheme.carAmber,
                                onChanged: (v) => dps.setHighGain(v),
                                onKillToggle: () {
                                  HapticFeedback.heavyImpact();
                                  dps.toggleHighKill();
                                },
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

  Widget _buildStemPresetChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.neonCyan.withAlpha(40) : Colors.white.withAlpha(12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.neonCyan : Colors.white24,
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isSelected ? AppTheme.neonCyan : Colors.white70),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppTheme.neonCyan : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDJIsolatorRow({
    required IconData icon,
    required String label,
    required String freqRange,
    required double value,
    required Color color,
    required ValueChanged<double> onChanged,
    required VoidCallback onKillToggle,
  }) {
    final isKilled = value <= -11.0;
    final isMax = value >= 11.0;

    String statusText;
    Color statusColor;
    if (isKilled) {
      statusText = 'KILLED (-∞ dB)';
      statusColor = Colors.redAccent;
    } else if (isMax) {
      statusText = 'MAX BOOST (+12 dB)';
      statusColor = AppTheme.carNeonGreen;
    } else if (value.abs() < 0.5) {
      statusText = 'FLAT (0 dB)';
      statusColor = Colors.white70;
    } else {
      statusText = '${value >= 0 ? "+" : ""}${value.toStringAsFixed(1)} dB';
      statusColor = color;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: isKilled ? Colors.redAccent : color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isKilled ? Colors.white54 : Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    freqRange,
                    style: const TextStyle(fontSize: 9.5, color: Colors.white38),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(25),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: statusColor.withAlpha(80), width: 0.8),
              ),
              child: Text(
                statusText,
                style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: statusColor),
              ),
            ),
            const SizedBox(width: 8),
            // Dedicated DJ KILL button with glowing neon border
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: onKillToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isKilled ? Colors.redAccent : Colors.redAccent.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.redAccent,
                    width: isKilled ? 1.5 : 0.8,
                  ),
                  boxShadow: [
                    if (isKilled)
                      BoxShadow(
                        color: Colors.redAccent.withAlpha(120),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: Text(
                  isKilled ? 'KILLED' : 'KILL',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: isKilled ? Colors.white : Colors.redAccent,
                  ),
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3.5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            activeTrackColor: isKilled ? Colors.white24 : color,
            inactiveTrackColor: Colors.white12,
            thumbColor: isKilled ? Colors.redAccent : Colors.white,
          ),
          child: Slider(
            value: value,
            min: -12.0,
            max: 12.0,
            divisions: 48,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
