import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dps_control.dart';
import '../models/acoustic_profile.dart';
import 'ad_service.dart';

class DPSEngine extends ChangeNotifier {
  DPSEngine._();
  static final DPSEngine instance = DPSEngine._();

  // Active DPS Preset parameters
  DPSPreset _activePreset = defaultPresets.first;
  bool _dpsEnabled = true;

  // Active Acoustic Output Profile (Earbuds/TWS, Over-Ear Headphones, Car Cockpit, Speaker)
  AcousticProfileType _activeDeviceProfile = AcousticProfileType.earbuds;

  DPSPreset get activePreset => _activePreset;
  bool get dpsEnabled => _dpsEnabled;
  AcousticProfileType get activeDeviceProfileType => _activeDeviceProfile;
  AcousticProfile get activeDeviceProfile => AcousticProfile.getProfile(_activeDeviceProfile);

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedType = prefs.getString('auramix_acoustic_profile');
      if (savedType != null) {
        final match = AcousticProfileType.values.firstWhere(
          (e) => e.name == savedType,
          orElse: () => AcousticProfileType.earbuds,
        );
        _activeDeviceProfile = match;
        _applyDeviceProfile(match, notify: false);
      } else {
        // Default to earbuds optimization
        _applyDeviceProfile(AcousticProfileType.earbuds, notify: false);
      }
    } catch (e) {
      debugPrint('[DPSEngine] initialize error: $e');
    }
  }

  void setAcousticProfile(AcousticProfileType type) {
    _activeDeviceProfile = type;
    _applyDeviceProfile(type, notify: true);

    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('auramix_acoustic_profile', type.name);
    }).catchError((_) {});

    AdService.instance.recordUserAction(reason: 'Acoustic Profile Changed to ${type.name}');
  }

  void _applyDeviceProfile(AcousticProfileType type, {bool notify = true}) {
    final profile = AcousticProfile.getProfile(type);
    _activePreset = _activePreset.copyWith(
      eqBands: List<double>.from(profile.eqBands),
      bassBoost: profile.bassBoost,
      surround3D: profile.surround3D,
      clarity: profile.clarity,
      tubeWarmth: profile.tubeWarmth,
      compressor: profile.compressor,
      reverbType: profile.reverbType,
      reverbMix: profile.reverbMix,
    );
    if (notify) {
      notifyListeners();
    }
  }

  void toggleDPSEnabled() {
    _dpsEnabled = !_dpsEnabled;
    notifyListeners();
    AdService.instance.recordUserAction(reason: 'DPS Toggled');
  }

  void loadPreset(DPSPreset preset) {
    _activePreset = preset;
    notifyListeners();
    AdService.instance.recordUserAction(reason: 'Preset Loaded');
  }

  void updateBand(int index, double gainDb) {
    if (index < 0 || index >= _activePreset.eqBands.length) return;
    final updatedBands = List<double>.from(_activePreset.eqBands);
    updatedBands[index] = gainDb.clamp(-12.0, 12.0);
    _activePreset = _activePreset.copyWith(eqBands: updatedBands);
    notifyListeners();
    AdService.instance.recordUserAction(reason: 'EQ Band Adjusted');
  }

  void resetEQ() {
    _activePreset = _activePreset.copyWith(eqBands: List.filled(10, 0.0));
    notifyListeners();
    AdService.instance.recordUserAction(reason: 'EQ Reset');
  }

  void setBassBoost(double value) {
    _activePreset = _activePreset.copyWith(bassBoost: value.clamp(0.0, 1.0));
    notifyListeners();
    AdService.instance.recordUserAction(reason: 'Bass Boost Adjusted');
  }

  void setSurround3D(double value) {
    _activePreset = _activePreset.copyWith(surround3D: value.clamp(0.0, 1.0));
    notifyListeners();
    AdService.instance.recordUserAction(reason: 'Surround 3D Adjusted');
  }

  void setClarity(double value) {
    _activePreset = _activePreset.copyWith(clarity: value.clamp(0.0, 1.0));
    notifyListeners();
    AdService.instance.recordUserAction(reason: 'Clarity Adjusted');
  }

  void setTubeWarmth(double value) {
    _activePreset = _activePreset.copyWith(tubeWarmth: value.clamp(0.0, 1.0));
    notifyListeners();
    AdService.instance.recordUserAction(reason: 'Tube Warmth Adjusted');
  }

  void setCompressor(double value) {
    _activePreset = _activePreset.copyWith(compressor: value.clamp(0.0, 1.0));
    notifyListeners();
    AdService.instance.recordUserAction(reason: 'Compressor Adjusted');
  }

  void setReverb(String type, double mix) {
    _activePreset = _activePreset.copyWith(reverbType: type, reverbMix: mix.clamp(0.0, 1.0));
    notifyListeners();
    AdService.instance.recordUserAction(reason: 'Reverb Adjusted');
  }

  void setPitchShift(double semitones) {
    _activePreset = _activePreset.copyWith(pitchShift: semitones.clamp(-12.0, 12.0));
    notifyListeners();
    AdService.instance.recordUserAction(reason: 'Pitch Shift Adjusted');
  }

  void setSpeed(double speed) {
    _activePreset = _activePreset.copyWith(speed: speed.clamp(0.5, 2.0));
    notifyListeners();
    AdService.instance.recordUserAction(reason: 'Speed Adjusted');
  }

  // Stem & Instrument Level Isolators
  void setVocalGain(double db) {
    _activePreset = _activePreset.copyWith(vocalGain: db.clamp(-12.0, 12.0));
    notifyListeners();
    AdService.instance.recordUserAction(reason: 'Vocal / Word Level Adjusted');
  }

  void setMusicGain(double db) {
    _activePreset = _activePreset.copyWith(musicGain: db.clamp(-12.0, 12.0));
    notifyListeners();
    AdService.instance.recordUserAction(reason: 'Music / Instrument Level Adjusted');
  }

  void setBassGain(double db) {
    _activePreset = _activePreset.copyWith(bassGain: db.clamp(-12.0, 12.0));
    notifyListeners();
    AdService.instance.recordUserAction(reason: 'Bass / Rhythm Level Adjusted');
  }

  void setTrebleGain(double db) {
    _activePreset = _activePreset.copyWith(trebleGain: db.clamp(-12.0, 12.0));
    notifyListeners();
    AdService.instance.recordUserAction(reason: 'Treble / Air Level Adjusted');
  }

  void resetStems() {
    _activePreset = _activePreset.copyWith(
      vocalGain: 0.0,
      musicGain: 0.0,
      bassGain: 0.0,
      trebleGain: 0.0,
    );
    notifyListeners();
    AdService.instance.recordUserAction(reason: 'Stems Reset');
  }

  static const List<String> eqFrequencies = [
    '31Hz',
    '63Hz',
    '125Hz',
    '250Hz',
    '500Hz',
    '1kHz',
    '2kHz',
    '4kHz',
    '8kHz',
    '16kHz',
  ];

  static final List<DPSPreset> defaultPresets = [
    DPSPreset(
      id: 'car_cockpit_turbo',
      title: 'Car Cockpit Turbo',
      description: 'Engineered specifically for car cabin acoustics with tight sub-bass and broad 3D imaging.',
      creator: 'AuraMix SoundLab',
      category: 'Car Audio',
      isPremium: false,
      likes: 2480,
      dislikes: 18,
      plays: 18200,
      eqBands: [6.5, 5.0, 3.5, 1.0, 0.0, 0.5, 2.0, 3.5, 5.0, 6.0],
      bassBoost: 0.85,
      surround3D: 0.70,
      clarity: 0.75,
      tubeWarmth: 0.40,
      compressor: 0.60,
      reverbType: 'Club',
      reverbMix: 0.25,
      recommendedSongs: [
        const SongRecommendation(
          title: 'Blinding Lights',
          artist: 'The Weeknd',
          comment: 'The synth-wave bassline roars inside car speakers with this preset!',
        ),
        const SongRecommendation(
          title: 'Starboy',
          artist: 'Daft Punk & The Weeknd',
          comment: 'Perfect vocal separation and punchy kick drums.',
        ),
      ],
    ),
    DPSPreset(
      id: 'sub_bass_tremor',
      title: 'Sub-Bass Tremor',
      description: 'Maximum sub-frequency extension without distortion. Great for Hip-Hop and Trap.',
      creator: 'BassMaster99',
      category: 'Bass Heavy',
      isPremium: false,
      likes: 1950,
      dislikes: 42,
      plays: 14300,
      eqBands: [9.0, 7.5, 5.0, 2.0, -1.0, 0.0, 1.0, 2.0, 3.0, 4.0],
      bassBoost: 0.95,
      surround3D: 0.40,
      clarity: 0.50,
      tubeWarmth: 0.50,
      compressor: 0.75,
      reverbType: 'Off',
      reverbMix: 0.10,
      recommendedSongs: [
        const SongRecommendation(
          title: 'Sicko Mode',
          artist: 'Travis Scott',
          comment: 'Subwoofers will shake the floorboards on this drop.',
        ),
      ],
    ),
    DPSPreset(
      id: 'audiophile_pure',
      title: 'Audiophile Master',
      description: 'Reference-grade linear frequency response with delicate vacuum tube harmonic richness.',
      creator: 'StudioPro',
      category: 'Acoustic',
      isPremium: true, // Premium control preset!
      likes: 3120,
      dislikes: 12,
      plays: 25400,
      eqBands: [1.0, 1.0, 0.5, 0.0, 0.0, 0.5, 1.0, 1.5, 2.5, 3.0],
      bassBoost: 0.40,
      surround3D: 0.50,
      clarity: 0.90,
      tubeWarmth: 0.85,
      compressor: 0.30,
      reverbType: 'Studio',
      reverbMix: 0.15,
      recommendedSongs: [
        const SongRecommendation(
          title: 'Hotel California (Live)',
          artist: 'Eagles',
          comment: '12-string acoustic guitar picks sparkle with pristine air.',
        ),
      ],
    ),
    DPSPreset(
      id: 'night_drive_synth',
      title: 'Night Drive 80s',
      description: 'Warm analog tube saturation, wide stereo field, and punchy snares for late night cruising.',
      creator: 'CyberRunner',
      category: 'Car Audio',
      isPremium: true, // Premium control preset!
      likes: 1720,
      dislikes: 15,
      plays: 11900,
      eqBands: [4.0, 3.5, 2.0, 0.5, -0.5, 1.0, 2.5, 3.5, 5.5, 5.0],
      bassBoost: 0.70,
      surround3D: 0.85,
      clarity: 0.70,
      tubeWarmth: 0.80,
      compressor: 0.65,
      reverbType: 'Arena',
      reverbMix: 0.30,
      recommendedSongs: [
        const SongRecommendation(
          title: 'Resonance',
          artist: 'HOME',
          comment: 'The definitive chill synthwave journey track.',
        ),
      ],
    ),
    DPSPreset(
      id: 'vocal_crisp_lead',
      title: 'Vocal Clarity Pro',
      description: 'Brings lead vocals and podcast voices straight to the front of the soundstage.',
      creator: 'AuraMix SoundLab',
      category: 'Vocal',
      isPremium: false,
      likes: 1420,
      dislikes: 21,
      plays: 9800,
      eqBands: [-2.0, -1.0, 0.0, 1.5, 3.0, 4.5, 4.0, 3.0, 2.0, 1.0],
      bassBoost: 0.30,
      surround3D: 0.45,
      clarity: 0.95,
      tubeWarmth: 0.35,
      compressor: 0.70,
      reverbType: 'Studio',
      reverbMix: 0.20,
      recommendedSongs: [
        const SongRecommendation(
          title: 'Someone Like You',
          artist: 'Adele',
          comment: 'Vocals stand out with zero acoustic clutter.',
        ),
      ],
    ),
  ];
}
