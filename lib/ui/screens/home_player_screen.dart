import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/app_theme.dart';
import '../../core/audio_player_service.dart';
import '../../core/dps_engine.dart';
import '../../models/song_item.dart';
import '../widgets/animated_visualizer.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/acoustic_profile_selector.dart';
import 'car_drive_mode_screen.dart';

class HomePlayerScreen extends StatefulWidget {
  final VoidCallback onOpenDPSStudio;

  const HomePlayerScreen({
    super.key,
    required this.onOpenDPSStudio,
  });

  @override
  State<HomePlayerScreen> createState() => _HomePlayerScreenState();
}

class _HomePlayerScreenState extends State<HomePlayerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _discRotator;
  int _viewMode = 0; // 0 = Cockpit Player Deck, 1 = Local Music Library
  String _searchQuery = '';
  int _libraryFilter = 0; // 0 = All, 1 = Device Audio, 2 = Bundled Sounds

  @override
  void initState() {
    super.initState();
    _discRotator = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    AudioPlayerService.instance.playerStateStream.listen((state) {
      if (state.playing) {
        if (!_discRotator.isAnimating) _discRotator.repeat();
      } else {
        if (_discRotator.isAnimating) _discRotator.stop();
      }
    });
  }

  @override
  void dispose() {
    _discRotator.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showScanResultSnackbar(int count, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF14243A),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.library_music_rounded, color: AppTheme.neonCyan),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                count > 0
                    ? '$action: Added $count new song${count > 1 ? "s" : ""} to library!'
                    : '$action: No new audio files found.',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlaylistSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131526),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final playlist = AudioPlayerService.instance.playlist;
        final currentSong = AudioPlayerService.instance.currentSong;

        return SafeArea(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Queue (${playlist.length} Tracks)',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final count = await AudioPlayerService.instance.scanDeviceMusicDirectory();
                            _showScanResultSnackbar(count, 'Device Scan');
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 16, color: AppTheme.neonCyan),
                          label: const Text('Scan Device', style: TextStyle(color: AppTheme.neonCyan, fontSize: 12)),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final count = await AudioPlayerService.instance.pickAudioFiles();
                            _showScanResultSnackbar(count, 'Import');
                          },
                          icon: const Icon(Icons.add, size: 16, color: AppTheme.carNeonGreen),
                          label: const Text('Add Files', style: TextStyle(color: AppTheme.carNeonGreen, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10),
              Expanded(
                child: ListView.builder(
                  itemCount: playlist.length,
                  itemBuilder: (ctx, idx) {
                    final song = playlist[idx];
                    final isCurrent = song.id == currentSong?.id;

                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isCurrent ? AppTheme.neonCyan.withAlpha(50) : Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isCurrent ? Icons.graphic_eq_rounded : Icons.music_note,
                          color: isCurrent ? AppTheme.neonCyan : Colors.white54,
                        ),
                      ),
                      title: Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCurrent ? AppTheme.neonCyan : Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        '${song.artist} · ${song.isAsset ? "Bundled Sound" : "Device Audio"}',
                        style: const TextStyle(fontSize: 11, color: Colors.white54),
                      ),
                      trailing: isCurrent
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.neonCyan.withAlpha(40),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.neonCyan.withAlpha(90)),
                              ),
                              child: const Text(
                                'PLAYING',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.neonCyan),
                              ),
                            )
                          : null,
                      onTap: () {
                        AudioPlayerService.instance.playSong(song);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AudioPlayerService.instance,
        DPSEngine.instance,
      ]),
      builder: (context, _) {
        final currentSong = AudioPlayerService.instance.currentSong;
        final isPlaying = AudioPlayerService.instance.isPlaying;
        final dps = DPSEngine.instance;
        final allSongs = AudioPlayerService.instance.playlist;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.queue_music_rounded, color: AppTheme.neonCyan),
              tooltip: 'Queue',
              onPressed: _showPlaylistSheet,
            ),
            title: const Text('AuraMix'),
            actions: [
              // Car HUD Mode button
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.carAmber.withAlpha(35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.carAmber.withAlpha(90)),
                  ),
                  child: const Icon(Icons.directions_car_filled_rounded, color: AppTheme.carAmber, size: 20),
                ),
                tooltip: 'Car HUD Mode',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CarDriveModeScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.file_upload_outlined, color: AppTheme.neonCyan),
                tooltip: 'Import Local Audio',
                onPressed: () async {
                  final count = await AudioPlayerService.instance.pickAudioFiles();
                  _showScanResultSnackbar(count, 'Import');
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Top Segmented Switch: Cockpit Deck vs. Local Music Library
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _viewMode = 0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _viewMode == 0 ? AppTheme.surfaceElevated : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: _viewMode == 0
                                    ? Border.all(color: AppTheme.neonCyan.withAlpha(120), width: 1.2)
                                    : null,
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.album_rounded,
                                      size: 16,
                                      color: _viewMode == 0 ? AppTheme.neonCyan : Colors.white54,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Now Playing',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: _viewMode == 0 ? FontWeight.bold : FontWeight.normal,
                                        color: _viewMode == 0 ? Colors.white : Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _viewMode = 1),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _viewMode == 1 ? AppTheme.surfaceElevated : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: _viewMode == 1
                                    ? Border.all(color: AppTheme.neonPurple.withAlpha(120), width: 1.2)
                                    : null,
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.library_music_rounded,
                                      size: 16,
                                      color: _viewMode == 1 ? AppTheme.neonPurple : Colors.white54,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'My Songs (${allSongs.length})',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: _viewMode == 1 ? FontWeight.bold : FontWeight.normal,
                                        color: _viewMode == 1 ? Colors.white : Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Main Content View
                Expanded(
                  child: _viewMode == 0
                      ? _buildCockpitPlayerView(currentSong, isPlaying, dps)
                      : _buildLocalLibraryView(currentSong, dps),
                ),

                // AdMob Banner at bottom
                const BannerAdWidget(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// View 0: Now Playing Deck with Disc, Visualizer, Transport, and Quick DPS Selector
  Widget _buildCockpitPlayerView(SongItem? currentSong, bool isPlaying, DPSEngine dps) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 4),

          // Active DPS Status Banner (Clickable to open DPS Studio)
          InkWell(
            onTap: widget.onOpenDPSStudio,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: dps.dpsEnabled
                      ? [const Color(0xFF16213E), const Color(0xFF0F3460)]
                      : [const Color(0xFF1E1E28), const Color(0xFF14141E)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: dps.dpsEnabled ? AppTheme.neonCyan.withAlpha(120) : Colors.white12,
                  width: 1.2,
                ),
                boxShadow: dps.dpsEnabled
                    ? [
                        BoxShadow(
                          color: AppTheme.neonCyan.withAlpha(40),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.electric_bolt_rounded,
                    color: dps.dpsEnabled ? AppTheme.neonCyan : Colors.white38,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              dps.dpsEnabled ? 'DPS EFFECT ACTIVE' : 'DPS BYPASSED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: dps.dpsEnabled ? AppTheme.neonCyan : Colors.white38,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.neonCyan.withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'CUSTOMIZE',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.neonCyan,
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, size: 12, color: AppTheme.neonCyan),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dps.activePreset.title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Acoustic Output Target Selector (Earbuds, Headphones, Car, Speaker)
          const AcousticProfileSelector(compact: true),
          const SizedBox(height: 12),

          // Quick DPS Preset Strip (1-tap effect switching while listening)
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: DPSEngine.defaultPresets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final preset = DPSEngine.defaultPresets[i];
                final isSelected = dps.activePreset.id == preset.id && dps.dpsEnabled;

                return GestureDetector(
                  onTap: () {
                    dps.loadPreset(preset);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.neonCyan.withAlpha(45) : AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppTheme.neonCyan : Colors.white12,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          const Icon(Icons.check, size: 12, color: AppTheme.neonCyan),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          preset.title,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Glowing Rotating Vinyl Turntable
          Center(
            child: AnimatedBuilder(
              animation: _discRotator,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _discRotator.value * 2 * pi,
                  child: child,
                );
              },
              child: Container(
                width: 175,
                height: 175,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFF0F1122),
                      Color(0xFF1B1E38),
                      Color(0xFF070914),
                    ],
                    stops: [0.2, 0.7, 1.0],
                  ),
                  border: Border.all(
                    color: isPlaying ? AppTheme.neonCyan.withAlpha(140) : Colors.white24,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isPlaying ? AppTheme.neonCyan.withAlpha(70) : Colors.black,
                      blurRadius: isPlaying ? 26 : 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Vinyl grooves
                    ...List.generate(3, (i) {
                      return Container(
                        width: 70.0 + (i * 28.0),
                        height: 70.0 + (i * 28.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withAlpha(10), width: 1),
                        ),
                      );
                    }),
                    // Center label
                    Container(
                      width: 62,
                      height: 62,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.cyanPurpleGradient,
                      ),
                      child: const Center(
                        child: Icon(Icons.album_rounded, size: 32, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Track Title and Artist
          Text(
            currentSong?.title ?? 'No Track Loaded',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            currentSong != null
                ? '${currentSong.artist} · ${currentSong.isAsset ? "Bundled Sound" : "Device Audio"}'
                : 'Import songs to experience DPS audio enhancement',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Animated Visualizer with Dual Analog VU Meters
          const AnimatedVisualizer(height: 50, showVUMeter: true),
          const SizedBox(height: 8),

          // Audio Seek Bar
          StreamBuilder<Duration>(
            stream: AudioPlayerService.instance.positionStream,
            builder: (context, posSnap) {
              final pos = posSnap.data ?? Duration.zero;
              return StreamBuilder<Duration?>(
                stream: AudioPlayerService.instance.durationStream,
                builder: (context, durSnap) {
                  final dur = durSnap.data ?? currentSong?.duration ?? const Duration(minutes: 3);
                  final maxMs = max(1, dur.inMilliseconds);
                  final curMs = pos.inMilliseconds.clamp(0, maxMs);

                  return Column(
                    children: [
                      Slider(
                        value: curMs.toDouble(),
                        max: maxMs.toDouble(),
                        onChanged: (val) {
                          AudioPlayerService.instance.seek(Duration(milliseconds: val.toInt()));
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(pos),
                              style: const TextStyle(fontSize: 11, color: Colors.white60),
                            ),
                            Text(
                              _formatDuration(dur),
                              style: const TextStyle(fontSize: 11, color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),

          // Transport Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  Icons.shuffle_rounded,
                  color: AudioPlayerService.instance.isShuffle ? AppTheme.neonCyan : Colors.white38,
                ),
                onPressed: () => AudioPlayerService.instance.toggleShuffle(),
              ),
              IconButton(
                iconSize: 32,
                icon: const Icon(Icons.skip_previous_rounded, color: Colors.white),
                onPressed: () => AudioPlayerService.instance.skipToPrevious(),
              ),
              GestureDetector(
                onTap: () => AudioPlayerService.instance.togglePlayPause(),
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.cyanPurpleGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.neonCyan.withAlpha(120),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 34,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                iconSize: 32,
                icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
                onPressed: () => AudioPlayerService.instance.skipToNext(),
              ),
              IconButton(
                icon: Icon(
                  AudioPlayerService.instance.loopMode == LoopMode.one
                      ? Icons.repeat_one_rounded
                      : Icons.repeat_rounded,
                  color: AudioPlayerService.instance.loopMode != LoopMode.off
                      ? AppTheme.neonCyan
                      : Colors.white38,
                ),
                onPressed: () => AudioPlayerService.instance.cycleLoopMode(),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  /// View 1: Local Music Library with Search, Device Scanner, and Tune With DPS
  Widget _buildLocalLibraryView(SongItem? currentSong, DPSEngine dps) {
    final allSongs = AudioPlayerService.instance.playlist;
    final isScanning = AudioPlayerService.instance.isScanning;

    // Apply Filter (All, Device, Bundled)
    var filtered = allSongs.where((s) {
      if (_libraryFilter == 1) return !s.isAsset;
      if (_libraryFilter == 2) return s.isAsset;
      return true;
    }).toList();

    // Apply Search Query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((s) {
        return s.title.toLowerCase().contains(q) || s.artist.toLowerCase().contains(q);
      }).toList();
    }

    return Column(
      children: [
        // Action Bar: Scan Device, Pick Files, Add Folder (Horizontally Scrollable)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: isScanning
                    ? null
                    : () async {
                        final count = await AudioPlayerService.instance.scanDeviceMusicDirectory();
                        _showScanResultSnackbar(count, 'Device Storage Scan');
                      },
                icon: isScanning
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.phonelink_ring_rounded, size: 15),
                label: Text(
                  isScanning ? 'Scanning...' : 'Scan Device Songs',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonCyan.withAlpha(45),
                  foregroundColor: AppTheme.neonCyan,
                  side: BorderSide(color: AppTheme.neonCyan.withAlpha(100)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final count = await AudioPlayerService.instance.pickAudioFiles();
                  _showScanResultSnackbar(count, 'Audio Picker');
                },
                icon: const Icon(Icons.file_open_rounded, size: 15),
                label: const Text('Pick Files', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final count = await AudioPlayerService.instance.pickMusicFolder();
                  _showScanResultSnackbar(count, 'Folder Import');
                },
                icon: const Icon(Icons.folder_open_rounded, size: 15),
                label: const Text('Folder', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),

        // Search Field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(fontSize: 13, color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search songs by title or artist...',
              hintStyle: const TextStyle(fontSize: 12, color: Colors.white38),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.neonCyan),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16, color: Colors.white54),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
              filled: true,
              fillColor: AppTheme.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.neonCyan),
              ),
            ),
          ),
        ),

        // Filter Chips (All, Device Audio, Bundled) - Scrollable
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          child: Row(
            children: [
              _buildFilterChip('All (${allSongs.length})', 0),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Device Tracks (${AudioPlayerService.instance.localDeviceSongs.length})',
                1,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Bundled (${AudioPlayerService.instance.bundledSounds.length})',
                2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Songs List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.music_off_rounded, size: 48, color: Colors.white.withAlpha(40)),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty ? 'No tracks matching "$_searchQuery"' : 'No audio files found',
                        style: const TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: () => AudioPlayerService.instance.pickAudioFiles(),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Songs Now'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, idx) {
                    final song = filtered[idx];
                    final isCurrent = song.id == currentSong?.id;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: isCurrent ? AppTheme.neonCyan.withAlpha(20) : AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isCurrent ? AppTheme.neonCyan.withAlpha(90) : Colors.white.withAlpha(12),
                          width: isCurrent ? 1.2 : 0.8,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: isCurrent ? AppTheme.cyanPurpleGradient : null,
                            color: isCurrent ? null : AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isCurrent
                                ? (AudioPlayerService.instance.isPlaying ? Icons.graphic_eq_rounded : Icons.play_arrow_rounded)
                                : (song.isAsset ? Icons.audiotrack_rounded : Icons.music_note_rounded),
                            color: isCurrent ? Colors.white : AppTheme.neonCyan,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                            color: isCurrent ? AppTheme.neonCyan : Colors.white,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Flexible(
                              child: Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Colors.white54),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: song.isAsset ? Colors.blue.withAlpha(35) : AppTheme.carNeonGreen.withAlpha(35),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                song.isAsset ? 'Demo' : 'Local',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: song.isAsset ? Colors.lightBlueAccent : AppTheme.carNeonGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tune With DPS button (plays track & switches to DPS Studio)
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                              icon: const Icon(Icons.tune_rounded, size: 18, color: AppTheme.neonCyan),
                              tooltip: 'Tune DPS for this song',
                              onPressed: () {
                                AudioPlayerService.instance.playSong(song);
                                widget.onOpenDPSStudio();
                              },
                            ),
                            const SizedBox(width: 4),
                            // Quick options menu
                            PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                              icon: const Icon(Icons.more_vert_rounded, size: 18, color: Colors.white38),
                              color: AppTheme.surfaceElevated,
                              onSelected: (val) {
                                if (val == 'play') {
                                  AudioPlayerService.instance.playSong(song);
                                } else if (val == 'tune') {
                                  AudioPlayerService.instance.playSong(song);
                                  widget.onOpenDPSStudio();
                                } else if (val == 'remove') {
                                  AudioPlayerService.instance.removeSong(song.id);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'play',
                                  child: Row(
                                    children: [
                                      Icon(Icons.play_arrow_rounded, color: AppTheme.neonCyan, size: 18),
                                      SizedBox(width: 8),
                                      Text('Play Track', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'tune',
                                  child: Row(
                                    children: [
                                      Icon(Icons.equalizer_rounded, color: AppTheme.neonPurple, size: 18),
                                      SizedBox(width: 8),
                                      Text('Customize DPS Effect', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                                if (!song.isAsset)
                                  const PopupMenuItem(
                                    value: 'remove',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline_rounded, color: AppTheme.neonPink, size: 18),
                                        SizedBox(width: 8),
                                        Text('Remove from Library', style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                          AudioPlayerService.instance.playSong(song);
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, int filterIndex) {
    final isSelected = _libraryFilter == filterIndex;
    return GestureDetector(
      onTap: () => setState(() => _libraryFilter = filterIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.neonCyan.withAlpha(45) : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.neonCyan : Colors.white12,
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.white60,
          ),
        ),
      ),
    );
  }
}
