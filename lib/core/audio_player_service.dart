import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_item.dart';
import 'dps_engine.dart';
import 'audio_fx_bridge.dart';
import 'ad_service.dart';

class AudioPlayerService extends ChangeNotifier {
  AudioPlayerService._();
  static final AudioPlayerService instance = AudioPlayerService._();

  final AudioPlayer _player = AudioPlayer();
  final List<SongItem> _playlist = [];
  ConcatenatingAudioSource? _playlistSource;
  int _currentIndex = 0;
  bool _isShuffle = false;
  LoopMode _loopMode = LoopMode.all;
  bool _isScanning = false;

  // Real-time Visualizer amplitude stream simulation (for spectrum bars & VU meter)
  Timer? _visualizerTimer;
  final ValueNotifier<List<double>> visualizerBands = ValueNotifier<List<double>>(List.filled(24, 0.05));
  final ValueNotifier<double> vuMeterLeft = ValueNotifier<double>(0.0);
  final ValueNotifier<double> vuMeterRight = ValueNotifier<double>(0.0);

  AudioPlayer get player => _player;
  List<SongItem> get playlist => List.unmodifiable(_playlist);
  List<SongItem> get localDeviceSongs => _playlist.where((s) => !s.isAsset).toList();
  List<SongItem> get bundledSounds => _playlist.where((s) => s.isAsset).toList();
  int get currentIndex => _currentIndex;
  SongItem? get currentSong => _playlist.isNotEmpty && _currentIndex < _playlist.length ? _playlist[_currentIndex] : null;
  bool get isPlaying => _player.playing;
  bool get isShuffle => _isShuffle;
  bool get isScanning => _isScanning;
  LoopMode get loopMode => _loopMode;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  static const List<SongItem> _defaultDemoSongs = [
    SongItem(
      id: 'demo_rain',
      title: 'Midnight Rain Drive',
      artist: 'AuraMix SynthLab',
      album: 'Cockpit Essentials',
      duration: Duration(minutes: 3, seconds: 45),
      path: 'assets/audio/rain.wav',
      isAsset: true,
    ),
    SongItem(
      id: 'demo_ocean',
      title: 'Deep Pacific Drift',
      artist: 'CyberCruise',
      album: 'Coastline Journey',
      duration: Duration(minutes: 4, seconds: 12),
      path: 'assets/audio/ocean.wav',
      isAsset: true,
    ),
    SongItem(
      id: 'demo_fire',
      title: 'Warm Tube Harmonic',
      artist: 'Analog Master',
      album: 'Acoustic Warmth',
      duration: Duration(minutes: 3, seconds: 30),
      path: 'assets/audio/fireplace.wav',
      isAsset: true,
    ),
    SongItem(
      id: 'demo_forest',
      title: 'Neon Canopy Echo',
      artist: 'Spatial Dimension',
      album: 'Surround Soundscapes',
      duration: Duration(minutes: 3, seconds: 15),
      path: 'assets/audio/forest.wav',
      isAsset: true,
    ),
  ];

  Future<void> initialize() async {
    // Populate bundled audiophile demo songs first
    _playlist.addAll(_defaultDemoSongs);

    // Restore previously imported or scanned user songs from local persistent storage
    await _loadSavedLocalSongs();

    // Loop mode default all so next/previous are continuously accessible in notifications
    _loopMode = LoopMode.all;
    try {
      await _player.setLoopMode(_loopMode);
    } catch (_) {}

    // Prepare playlist queue for Android MediaSession notifications (enables Next/Previous buttons)
    if (_playlist.isNotEmpty) {
      _playlistSource = _buildConcatenatingAudioSource();
      try {
        await _player.setAudioSource(_playlistSource!, initialIndex: 0, preload: false);
      } catch (e) {
        debugPrint('[AudioPlayerService] Error setting initial source: $e');
      }
    }

    // Automatically sync active track when user taps Next/Previous from notification / lock screen / auto-advance
    _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _playlist.length) {
        if (_currentIndex != index) {
          _currentIndex = index;
          notifyListeners();
        }
      }
    });

    // Listen to player completions
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        skipToNext();
      }
      notifyListeners();
    });

    // Pause automatically when headphones / earbuds are unplugged
    try {
      final session = await AudioSession.instance;
      session.becomingNoisyEventStream.listen((_) {
        debugPrint('[AudioPlayerService] Becoming noisy: headphones unplugged, pausing audio.');
        if (_player.playing) {
          _player.pause();
        }
      });
    } catch (e) {
      debugPrint('[AudioPlayerService] AudioSession setup error: $e');
    }

    // Connect real-time hardware DSP Audio Effects (Equalizer, BassBoost, Virtualizer, Loudness)
    _player.androidAudioSessionIdStream.listen((sessionId) {
      if (sessionId != null) {
        AudioFxBridge.instance.attachToSession(sessionId);
      }
    });

    // Sync DPS pitch, speed, and real-time DSP audio effects
    DPSEngine.instance.addListener(() {
      final active = DPSEngine.instance.activePreset;
      if (DPSEngine.instance.dpsEnabled) {
        _player.setSpeed(active.speed);
        try {
          _player.setPitch(pow(2.0, active.pitchShift / 12.0).toDouble());
        } catch (_) {}

        // Master brickwall mute if all 3 DJ isolator bands are killed
        if (active.bassGain <= -11.0 &&
            active.musicGain <= -11.0 &&
            active.trebleGain <= -11.0) {
          _player.setVolume(0.0);
        } else {
          _player.setVolume(1.0);
        }
      } else {
        _player.setSpeed(1.0);
        try {
          _player.setPitch(1.0);
        } catch (_) {}
        _player.setVolume(1.0);
      }

      // Sync hardware Equalizer, BassBoost, Virtualizer, and Stem filters in real-time
      AudioFxBridge.instance.syncEffects();
    });

    _startVisualizerLoop();
  }

  Future<void> _loadSavedLocalSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList('auramix_saved_local_songs') ?? [];
      for (final raw in jsonList) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          final song = SongItem.fromJson(map);
          // Check that the file still exists on disk and is not duplicate
          if (!song.isAsset && File(song.path).existsSync()) {
            if (!_playlist.any((s) => s.path == song.path)) {
              _playlist.insert(0, song);
            }
          }
        } catch (e) {
          debugPrint('[AudioPlayerService] Error parsing saved song: $e');
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[AudioPlayerService] Error loading saved songs: $e');
    }
  }

  Future<void> _saveLocalSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localOnly = _playlist.where((s) => !s.isAsset).toList();
      final encodedList = localOnly.map((s) => jsonEncode(s.toJson())).toList();
      await prefs.setStringList('auramix_saved_local_songs', encodedList);
    } catch (e) {
      debugPrint('[AudioPlayerService] Error saving songs: $e');
    }
  }

  /// Builds a ConcatenatingAudioSource containing the entire playlist queue with MediaItem metadata.
  /// This enables the system notification, lock screen, and Bluetooth devices to show Next & Previous controls.
  ConcatenatingAudioSource _buildConcatenatingAudioSource() {
    return ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: _playlist.map((song) {
        final mediaItem = MediaItem(
          id: song.id,
          album: song.album,
          title: song.title,
          artist: song.artist,
          duration: song.duration,
          artUri: Uri.parse('asset:///assets/images/auramix_icon.png'),
        );
        if (song.isAsset) {
          return AudioSource.asset(song.path, tag: mediaItem);
        } else {
          return AudioSource.uri(Uri.file(song.path), tag: mediaItem);
        }
      }).toList(),
    );
  }

  /// Syncs changes to the playlist queue directly into the running player
  Future<void> _syncPlaylistToPlayer({int? targetIndex}) async {
    if (_playlist.isEmpty) {
      _playlistSource = null;
      await _player.stop();
      return;
    }
    final index = targetIndex ?? _currentIndex.clamp(0, _playlist.length - 1);
    final wasPlaying = _player.playing;
    final currentPos = _player.position;

    _playlistSource = _buildConcatenatingAudioSource();
    try {
      await _player.setAudioSource(
        _playlistSource!,
        initialIndex: index,
        initialPosition: wasPlaying ? currentPos : Duration.zero,
      );
      if (wasPlaying) {
        await _player.play();
      }
    } catch (e) {
      debugPrint('[AudioPlayerService] _syncPlaylistToPlayer error: $e');
    }
  }

  void _startVisualizerLoop() {
    final rand = Random();
    _visualizerTimer = Timer.periodic(const Duration(milliseconds: 60), (_) {
      if (!_player.playing) {
        visualizerBands.value = List.generate(
          24,
          (i) => 0.05 + 0.03 * sin(DateTime.now().millisecondsSinceEpoch / 400 + i),
        );
        vuMeterLeft.value = (vuMeterLeft.value * 0.8).clamp(0.0, 1.0);
        vuMeterRight.value = (vuMeterRight.value * 0.8).clamp(0.0, 1.0);
        return;
      }

      final dps = DPSEngine.instance.activePreset;
      final bassMult = DPSEngine.instance.dpsEnabled ? 0.6 + dps.bassBoost * 0.8 : 0.7;
      final clarityMult = DPSEngine.instance.dpsEnabled ? 0.6 + dps.clarity * 0.8 : 0.7;

      final List<double> newBands = [];
      for (int i = 0; i < 24; i++) {
        double mult = i < 8 ? bassMult : (i > 16 ? clarityMult : 0.8);
        double val = (rand.nextDouble() * 0.7 + 0.3) * mult;
        newBands.add(val.clamp(0.05, 1.0));
      }
      visualizerBands.value = newBands;

      final avgBass = (newBands[0] + newBands[1] + newBands[2]) / 3;
      final avgHigh = (newBands[20] + newBands[21] + newBands[22]) / 3;
      vuMeterLeft.value = (avgBass * 0.85 + rand.nextDouble() * 0.15).clamp(0.05, 0.98);
      vuMeterRight.value = (avgHigh * 0.85 + rand.nextDouble() * 0.15).clamp(0.05, 0.98);
    });
  }

  /// Request permissions for local media
  Future<bool> checkOrRequestPermissions() async {
    if (Platform.isAndroid) {
      final audioStatus = await Permission.audio.request();
      if (audioStatus.isGranted) return true;
      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    } else if (Platform.isIOS) {
      final mediaStatus = await Permission.mediaLibrary.request();
      return mediaStatus.isGranted;
    }
    return true;
  }

  /// Automatically scan standard music & audio folders on the device
  Future<int> scanDeviceMusicDirectory() async {
    final hasPerm = await checkOrRequestPermissions();
    if (!hasPerm) return 0;

    _isScanning = true;
    notifyListeners();

    int addedCount = 0;
    final supportedExts = {'.mp3', '.wav', '.m4a', '.flac', '.aac', '.ogg'};

    try {
      final List<Directory> dirsToScan = [];

      if (Platform.isAndroid) {
        final commonPaths = [
          '/storage/emulated/0/Music',
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Audiobooks',
          '/storage/emulated/0/Podcasts',
          '/storage/emulated/0/media',
          '/storage/emulated/0/Ringtones',
        ];
        for (final p in commonPaths) {
          final dir = Directory(p);
          if (dir.existsSync()) dirsToScan.add(dir);
        }
      }

      for (final dir in dirsToScan) {
        try {
          final entities = dir.listSync(recursive: true, followLinks: false);
          for (final entity in entities) {
            if (entity is File) {
              final ext = entity.path.toLowerCase().substring(entity.path.lastIndexOf('.'));
              if (supportedExts.contains(ext)) {
                if (!_playlist.any((s) => s.path == entity.path)) {
                  final fileName = entity.uri.pathSegments.last;
                  final title = fileName.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '').replaceAll('_', ' ');
                  final song = SongItem(
                    id: 'scan_${DateTime.now().millisecondsSinceEpoch}_$addedCount',
                    title: title,
                    artist: 'Device Audio',
                    album: dir.path.split('/').last,
                    duration: const Duration(minutes: 3, seconds: 30),
                    path: entity.path,
                    isAsset: false,
                  );
                  _playlist.insert(0, song);
                  addedCount++;
                }
              }
            }
          }
        } catch (e) {
          debugPrint('[AudioPlayerService] Error scanning dir ${dir.path}: $e');
        }
      }

      if (addedCount > 0) {
        await _saveLocalSongs();
        await _syncPlaylistToPlayer();
      }
    } finally {
      _isScanning = false;
      notifyListeners();
    }

    return addedCount;
  }

  /// Pick multiple individual audio files via system file picker
  Future<int> pickAudioFiles() async {
    await checkOrRequestPermissions();
    int addedCount = 0;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'flac', 'aac', 'ogg'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        for (final file in result.files) {
          if (file.path != null && !_playlist.any((s) => s.path == file.path)) {
            final fileName = file.name;
            final title = fileName.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '').replaceAll('_', ' ');
            final song = SongItem(
              id: 'local_${DateTime.now().millisecondsSinceEpoch}_$addedCount',
              title: title,
              artist: 'Local Music',
              album: 'Imported Tracks',
              duration: Duration(milliseconds: max(60000, file.size ~/ 30)),
              path: file.path!,
              isAsset: false,
            );
            _playlist.insert(0, song);
            addedCount++;
          }
        }

        if (addedCount > 0) {
          await _saveLocalSongs();
          _currentIndex = 0;
          await playSong(_playlist[0]);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[AudioPlayerService] File picker error: $e');
    }

    return addedCount;
  }

  /// Pick a whole folder and import all audio tracks inside it
  Future<int> pickMusicFolder() async {
    await checkOrRequestPermissions();
    int addedCount = 0;

    try {
      final folderPath = await FilePicker.platform.getDirectoryPath();
      if (folderPath != null) {
        final dir = Directory(folderPath);
        if (dir.existsSync()) {
          final supportedExts = {'.mp3', '.wav', '.m4a', '.flac', '.aac', '.ogg'};
          final entities = dir.listSync(recursive: true, followLinks: false);
          for (final entity in entities) {
            if (entity is File) {
              final dotIdx = entity.path.lastIndexOf('.');
              if (dotIdx != -1) {
                final ext = entity.path.toLowerCase().substring(dotIdx);
                if (supportedExts.contains(ext) && !_playlist.any((s) => s.path == entity.path)) {
                  final fileName = entity.uri.pathSegments.last;
                  final title = fileName.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '').replaceAll('_', ' ');
                  final song = SongItem(
                    id: 'folder_${DateTime.now().millisecondsSinceEpoch}_$addedCount',
                    title: title,
                    artist: 'Folder Import',
                    album: dir.path.split('/').last,
                    duration: const Duration(minutes: 3, seconds: 30),
                    path: entity.path,
                    isAsset: false,
                  );
                  _playlist.insert(0, song);
                  addedCount++;
                }
              }
            }
          }

          if (addedCount > 0) {
            await _saveLocalSongs();
            await _syncPlaylistToPlayer();
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('[AudioPlayerService] Folder pick error: $e');
    }

    return addedCount;
  }

  /// Remove a single song from the library
  Future<void> removeSong(String songId) async {
    final idx = _playlist.indexWhere((s) => s.id == songId);
    if (idx != -1) {
      final wasCurrent = _currentIndex == idx;
      _playlist.removeAt(idx);
      if (_playlist.isEmpty) {
        _currentIndex = 0;
        _playlistSource = null;
        await _player.stop();
      } else {
        if (_currentIndex >= _playlist.length) {
          _currentIndex = _playlist.length - 1;
        }
        await _syncPlaylistToPlayer(targetIndex: _currentIndex);
        if (wasCurrent) {
          await playSong(_playlist[_currentIndex]);
        }
      }
      await _saveLocalSongs();
      notifyListeners();
    }
  }

  /// Clear all imported songs, leaving bundled demo sounds
  Future<void> clearImportedSongs() async {
    _playlist.removeWhere((s) => !s.isAsset);
    if (_playlist.isEmpty) {
      _playlist.addAll(_defaultDemoSongs);
    }
    _currentIndex = 0;
    await _saveLocalSongs();
    await _syncPlaylistToPlayer(targetIndex: 0);
    notifyListeners();
  }

  /// Rearranges songs in the playlist when user drags and drops
  Future<void> reorderPlaylist(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _playlist.length) return;
    if (newIndex < 0 || newIndex > _playlist.length) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final currentPlayingSong = currentSong;
    final song = _playlist.removeAt(oldIndex);
    _playlist.insert(newIndex, song);

    // Keep currentIndex pointing to the same playing song
    if (currentPlayingSong != null) {
      _currentIndex = _playlist.indexWhere((s) => s.id == currentPlayingSong.id);
      if (_currentIndex == -1) _currentIndex = 0;
    }

    if (_playlistSource != null && _playlistSource!.length == _playlist.length) {
      try {
        await _playlistSource!.move(oldIndex, newIndex);
      } catch (e) {
        debugPrint('[AudioPlayerService] playlist move error: $e');
        await _syncPlaylistToPlayer(targetIndex: _currentIndex);
      }
    } else {
      await _syncPlaylistToPlayer(targetIndex: _currentIndex);
    }

    await _saveLocalSongs();
    notifyListeners();
  }

  /// Plays a song with the active DPS preset effect applied in real-time.
  /// Uses ConcatenatingAudioSource so that Android MediaSession automatically displays
  /// Next and Previous buttons in the notification bar, lock screen, and Bluetooth devices.
  Future<void> playSong(SongItem song) async {
    final idx = _playlist.indexWhere((s) => s.id == song.id);
    if (idx != -1) _currentIndex = idx;

    try {
      if (_playlistSource == null || _playlistSource!.length != _playlist.length) {
        _playlistSource = _buildConcatenatingAudioSource();
        await _player.setAudioSource(
          _playlistSource!,
          initialIndex: _currentIndex,
          initialPosition: Duration.zero,
        );
      } else {
        if (_player.currentIndex != _currentIndex) {
          await _player.seek(Duration.zero, index: _currentIndex);
        }
      }
      await _player.play();
      if (_player.androidAudioSessionId != null) {
        AudioFxBridge.instance.attachToSession(_player.androidAudioSessionId);
      }
      notifyListeners();
      AdService.instance.recordUserAction(reason: 'Audio Track Changed');
    } catch (e) {
      debugPrint('[AudioPlayerService] playSong error: $e');
    }
  }

  Future<void> togglePlayPause() async {
    if (_playlist.isEmpty) return;
    if (_player.playing) {
      await _player.pause();
    } else {
      if (_player.audioSource == null && currentSong != null) {
        await playSong(currentSong!);
      } else {
        await _player.play();
      }
    }
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> skipToNext() async {
    if (_playlist.isEmpty) return;
    try {
      if (_player.hasNext) {
        await _player.seekToNext();
        await _player.play();
      } else {
        _currentIndex = (_currentIndex + 1) % _playlist.length;
        if (_playlistSource != null && _playlistSource!.length == _playlist.length) {
          await _player.seek(Duration.zero, index: _currentIndex);
          await _player.play();
        } else {
          await playSong(_playlist[_currentIndex]);
        }
      }
    } catch (e) {
      _currentIndex = (_currentIndex + 1) % _playlist.length;
      await playSong(_playlist[_currentIndex]);
    }
  }

  Future<void> skipToPrevious() async {
    if (_playlist.isEmpty) return;
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    try {
      if (_player.hasPrevious) {
        await _player.seekToPrevious();
        await _player.play();
      } else {
        _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
        if (_playlistSource != null && _playlistSource!.length == _playlist.length) {
          await _player.seek(Duration.zero, index: _currentIndex);
          await _player.play();
        } else {
          await playSong(_playlist[_currentIndex]);
        }
      }
    } catch (e) {
      _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
      await playSong(_playlist[_currentIndex]);
    }
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    _player.setShuffleModeEnabled(_isShuffle);
    notifyListeners();
  }

  void cycleLoopMode() {
    if (_loopMode == LoopMode.off) {
      _loopMode = LoopMode.all;
    } else if (_loopMode == LoopMode.all) {
      _loopMode = LoopMode.one;
    } else {
      _loopMode = LoopMode.all;
    }
    _player.setLoopMode(_loopMode);
    notifyListeners();
  }

  @override
  void dispose() {
    _visualizerTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}
