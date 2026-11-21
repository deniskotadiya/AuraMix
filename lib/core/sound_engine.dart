import 'package:just_audio/just_audio.dart';

/// One independent player per ambient layer. Assets are original synthesized
/// placeholder ambience, replace them with licensed recordings before release.
class SoundEngine {
  SoundEngine._();
  static final SoundEngine instance = SoundEngine._();
  final Map<String, AudioPlayer> _players = {};
  final Map<String, String> _assets = {
    'Rain': 'assets/audio/rain.wav', 'Ocean': 'assets/audio/ocean.wav',
    'Forest': 'assets/audio/forest.wav', 'Fireplace': 'assets/audio/fireplace.wav',
    'Wind': 'assets/audio/wind.wav', 'Birds': 'assets/audio/birds.wav',
    'White Noise': 'assets/audio/white_noise.wav', 'Brown Noise': 'assets/audio/brown_noise.wav',
    'Pink Noise': 'assets/audio/pink_noise.wav', 'Cafe': 'assets/audio/cafe.wav',
  };
  Future<AudioPlayer> _player(String sound) async {
    if (_players.containsKey(sound)) return _players[sound]!;
    final p = AudioPlayer();
    final asset = _assets[sound];
    if (asset != null) await p.setAsset(asset);
    await p.setLoopMode(LoopMode.one);
    _players[sound] = p;
    return p;
  }
  Future<void> toggle(String sound) async {
    final p = await _player(sound);
    if (p.playing) { await p.pause(); } else { await p.play(); }
  }
  Future<void> setVolume(String sound, double volume) async => (await _player(sound)).setVolume(volume.clamp(0.0, 1.0).toDouble());
  Future<void> stopAll() async { for (final p in _players.values) { await p.stop(); } }
  Future<void> dispose() async { for (final p in _players.values) { await p.dispose(); } _players.clear(); }
}
