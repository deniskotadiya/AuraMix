import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dps_engine.dart';

class AudioFxBridge {
  AudioFxBridge._();
  static final AudioFxBridge instance = AudioFxBridge._();

  static const MethodChannel _channel = MethodChannel('com.squareinfosoft.auramix/audiofx');
  int? _currentSessionId;
  bool _initialized = false;

  void attachToSession(int? sessionId) {
    if (!Platform.isAndroid || sessionId == null || sessionId <= 0) return;
    if (_currentSessionId == sessionId && _initialized) return;

    _currentSessionId = sessionId;
    _initialized = true;

    _channel.invokeMethod('initSession', {'sessionId': sessionId}).then((_) {
      debugPrint('[AudioFxBridge] Attached native DSP audiofx to session $sessionId');
      syncEffects();
    }).catchError((e) {
      debugPrint('[AudioFxBridge] initSession error: $e');
    });
  }

  void syncEffects() {
    if (!Platform.isAndroid || !_initialized || _currentSessionId == null) return;

    final dps = DPSEngine.instance;
    final active = dps.activePreset;

    if (!dps.dpsEnabled) {
      _channel.invokeMethod('setEnabled', {'enabled': false}).catchError((_) {});
      return;
    }

    _channel.invokeMethod('setEnabled', {'enabled': true}).catchError((_) {});

    // 1. Equalizer 5-Band mapping from 10 EQ bands + Stem Isolators
    // Android hardware EQ levels are in millibels (-1500 to +1500, where 1 dB = 100 mB)
    final band0 = ((active.eqBands[0] * 70) + (active.bassGain * 160) + (active.bassBoost * 200)).round().clamp(-1500, 1500);
    final band1 = ((active.eqBands[2] * 80) + (active.bassGain * 100) + (active.musicGain * 80)).round().clamp(-1500, 1500);
    final band2 = ((active.eqBands[4] * 90) + (active.musicGain * 140) + (active.vocalGain * 80)).round().clamp(-1500, 1500);
    final band3 = ((active.eqBands[6] * 90) + (active.vocalGain * 220) + (active.clarity * 150)).round().clamp(-1500, 1500);
    final band4 = ((active.eqBands[9] * 80) + (active.trebleGain * 180) + (active.tubeWarmth * 100)).round().clamp(-1500, 1500);

    _channel.invokeMethod('setEqualizerBands', {
      'levels': [band0, band1, band2, band3, band4],
    }).catchError((e) => debugPrint('[AudioFxBridge] setEqualizerBands error: $e'));

    // 2. Hardware BassBoost strength (0 to 1000)
    final bassFactor = ((active.bassBoost * 0.75 + (active.bassGain > 0 ? (active.bassGain / 6.0) * 0.25 : 0.0)) * 1000).round().clamp(0, 1000);
    _channel.invokeMethod('setBassBoost', {'strength': bassFactor}).catchError((_) {});

    // 3. Hardware Virtualizer / 3D Spatializer (0 to 1000)
    final virtualizerFactor = (active.surround3D * 1000).round().clamp(0, 1000);
    _channel.invokeMethod('setVirtualizer', {'strength': virtualizerFactor}).catchError((_) {});

    // 4. Dynamic Loudness & Compression
    final loudnessGain = ((active.compressor * 0.6 + active.clarity * 0.4) * 800).round().clamp(0, 1200);
    _channel.invokeMethod('setLoudness', {'gain': loudnessGain}).catchError((_) {});

    // 5. Environmental Reverb Preset
    int revPreset = 0;
    switch (active.reverbType) {
      case 'Studio':
        revPreset = 1; // SmallRoom
        break;
      case 'Club':
        revPreset = 2; // MediumRoom
        break;
      case 'Arena':
        revPreset = 3; // LargeRoom
        break;
      case 'Cathedral':
        revPreset = 4; // MediumHall
        break;
      default:
        revPreset = 0; // None
    }
    _channel.invokeMethod('setReverb', {'preset': revPreset}).catchError((_) {});
  }
}
