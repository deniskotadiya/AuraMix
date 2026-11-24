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

    // 1. Calculate Stem Equalization with full Isolator kill-switch capability
    // Range is -1500 mB (-15 dB) to +1500 mB (+15 dB)
    // Paired with DynamicsProcessing (-60 dB brickwall), this makes any stem completely unlistenable when killed.
    final isVocalMuted = active.vocalGain <= -10.0;
    final isBassMuted = active.bassGain <= -10.0;
    final isMusicMuted = active.musicGain <= -10.0;
    final isTrebleMuted = active.trebleGain <= -10.0;

    // Band 0 (~60 Hz: Sub-bass, Kick, 808s)
    int band0;
    if (isBassMuted) {
      band0 = -1500; // Total kill of sub-bass
    } else if (active.bassGain < 0) {
      band0 = ((active.eqBands[0] * 60) + (active.bassGain * 125)).round().clamp(-1500, 1500);
    } else {
      band0 = ((active.eqBands[0] * 60) + (active.bassGain * 110) + (active.bassBoost * 400)).round().clamp(-1500, 1500);
    }

    // Band 1 (~230 Hz: Bass punch, lower rhythm & vocal chest resonance)
    int band1;
    if (isBassMuted && (isVocalMuted || isMusicMuted)) {
      band1 = -1500; // Complete kill
    } else if (isBassMuted) {
      band1 = isMusicMuted ? -1500 : -1400;
    } else if (isVocalMuted && isMusicMuted) {
      band1 = -1300 + (active.bassGain * 40).round();
    } else {
      final bassContrib = active.bassGain * 80;
      final musicContrib = active.musicGain * 60;
      final vocalContrib = active.vocalGain < 0 ? active.vocalGain * 50 : 0.0;
      band1 = ((active.eqBands[2] * 70) + bassContrib + musicContrib + vocalContrib).round().clamp(-1500, 1500);
    }

    // Band 2 (~910 Hz: Music body & human vocal formant)
    int band2;
    if (isVocalMuted || isMusicMuted) {
      band2 = -1500; // Complete kill of vocal body and harmonic instruments
    } else {
      final vocalContrib = active.vocalGain * 120;
      final musicContrib = active.musicGain * 80;
      band2 = ((active.eqBands[4] * 70) + vocalContrib + musicContrib).round().clamp(-1500, 1500);
    }

    // Band 3 (~3.6 kHz: Words, lyrics, vocal articulation & snare attack)
    int band3;
    if (isVocalMuted || isTrebleMuted) {
      band3 = -1500; // Complete kill of speech articulation / lyrics / words
    } else {
      final vocalContrib = active.vocalGain * 130;
      final trebleContrib = active.trebleGain * 60;
      band3 = ((active.eqBands[6] * 70) + vocalContrib + trebleContrib + (active.clarity * 200)).round().clamp(-1500, 1500);
    }

    // Band 4 (~14 kHz: Treble, air, cymbals, acoustic shimmer)
    int band4;
    if (isTrebleMuted || (isMusicMuted && active.trebleGain <= 0)) {
      band4 = -1500; // Complete kill of cymbals, shimmer & treble air
    } else if (active.trebleGain < 0) {
      band4 = ((active.eqBands[9] * 70) + (active.trebleGain * 125)).round().clamp(-1500, 1500);
    } else {
      band4 = ((active.eqBands[9] * 70) + (active.trebleGain * 120) + (active.tubeWarmth * 150)).round().clamp(-1500, 1500);
    }

    _channel.invokeMethod('setEqualizerBands', {
      'levels': [band0, band1, band2, band3, band4],
    }).catchError((e) => debugPrint('[AudioFxBridge] setEqualizerBands error: $e'));

    // 2. Hardware BassBoost strength (0 to 1000)
    int bassFactor;
    if (isBassMuted || active.bassGain <= -6.0) {
      bassFactor = 0; // Completely off
    } else {
      bassFactor = ((active.bassBoost * 0.70 + (active.bassGain > 0 ? (active.bassGain / 12.0) * 0.30 : 0.0)) * 1000).round().clamp(0, 1000);
    }
    _channel.invokeMethod('setBassBoost', {'strength': bassFactor}).catchError((_) {});

    // 3. Hardware Virtualizer (3D Spatializer)
    // When vocal is muted, Virtualizer phase difference cancels center-panned vocals!
    int virtualizerFactor;
    if (isVocalMuted) {
      virtualizerFactor = 1000;
    } else if (isMusicMuted) {
      virtualizerFactor = 0; // Collapse stereo field
    } else {
      virtualizerFactor = (active.surround3D * 1000).round().clamp(0, 1000);
    }
    _channel.invokeMethod('setVirtualizer', {'strength': virtualizerFactor}).catchError((_) {});

    // 4. Dynamic Loudness & Compression
    final loudnessGain = ((active.compressor * 0.6 + active.clarity * 0.4) * 800).round().clamp(0, 1200);
    _channel.invokeMethod('setLoudness', {'gain': loudnessGain}).catchError((_) {});

    // 5. Environmental Reverb Preset
    int revPreset = 0;
    switch (active.reverbType) {
      case 'Studio':
        revPreset = 1;
        break;
      case 'Club':
        revPreset = 2;
        break;
      case 'Arena':
        revPreset = 3;
        break;
      case 'Cathedral':
        revPreset = 4;
        break;
      default:
        revPreset = 0;
    }
    _channel.invokeMethod('setReverb', {'preset': revPreset}).catchError((_) {});
  }
}
