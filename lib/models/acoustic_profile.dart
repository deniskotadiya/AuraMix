import 'package:flutter/material.dart';

enum AcousticProfileType {
  earbuds,    // Earbuds & In-Ear Monitors (AirPods, Galaxy Buds, TWS, IEMs)
  headphones, // Over-Ear Studio & ANC Headphones
  car,        // Car Audio & Vehicle Soundstage
  speaker,    // Built-in Phone Speaker & External Bluetooth Box
}

class AcousticProfile {
  final AcousticProfileType type;
  final String title;
  final String shortLabel;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<double> eqBands;
  final double bassBoost;
  final double surround3D;
  final double clarity;
  final double tubeWarmth;
  final double compressor;
  final String reverbType;
  final double reverbMix;

  const AcousticProfile({
    required this.type,
    required this.title,
    required this.shortLabel,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.eqBands,
    required this.bassBoost,
    required this.surround3D,
    required this.clarity,
    required this.tubeWarmth,
    required this.compressor,
    required this.reverbType,
    required this.reverbMix,
  });

  static const List<AcousticProfile> defaultProfiles = [
    AcousticProfile(
      type: AcousticProfileType.earbuds,
      title: 'Earbuds & In-Ear',
      shortLabel: 'Earbuds / TWS',
      subtitle: 'AirPods, Galaxy Buds, TWS & IEMs',
      description: 'Acoustic seal compensation, deep sub-bass extension, sibilance reduction, and in-ear binaural 3D crossfeed.',
      icon: Icons.headphones_rounded,
      eqBands: [5.5, 4.0, 2.5, 0.5, -0.5, 0.5, 1.5, 2.0, 3.5, 5.0],
      bassBoost: 0.85,
      surround3D: 0.70,
      clarity: 0.85,
      tubeWarmth: 0.45,
      compressor: 0.55,
      reverbType: 'Studio',
      reverbMix: 0.15,
    ),
    AcousticProfile(
      type: AcousticProfileType.headphones,
      title: 'Over-Ear Headphones',
      shortLabel: 'Over-Ear',
      subtitle: 'Studio Monitors & ANC Headsets',
      description: 'Open studio acoustic room simulation, high-impedance linear frequency response, and vacuum-tube harmonic warmth.',
      icon: Icons.headset_rounded,
      eqBands: [3.0, 2.5, 1.5, 0.5, 0.0, 0.5, 1.0, 2.0, 3.0, 4.0],
      bassBoost: 0.65,
      surround3D: 0.90,
      clarity: 0.90,
      tubeWarmth: 0.75,
      compressor: 0.45,
      reverbType: 'Arena',
      reverbMix: 0.20,
    ),
    AcousticProfile(
      type: AcousticProfileType.car,
      title: 'Vehicle Cockpit',
      shortLabel: 'Car Audio',
      subtitle: 'Car Stereo & Bluetooth Cabin',
      description: 'Engineered specifically for car cabin acoustics: dynamic road-noise compression, low-end punch, and wide stereo image.',
      icon: Icons.directions_car_rounded,
      eqBands: [7.0, 5.5, 3.5, 1.0, 0.0, 0.5, 2.0, 3.5, 5.0, 6.0],
      bassBoost: 0.90,
      surround3D: 0.75,
      clarity: 0.75,
      tubeWarmth: 0.50,
      compressor: 0.75,
      reverbType: 'Club',
      reverbMix: 0.25,
    ),
    AcousticProfile(
      type: AcousticProfileType.speaker,
      title: 'Phone & Portable Speaker',
      shortLabel: 'Speaker',
      subtitle: 'Phone Loudspeaker & Portable BT',
      description: 'Anti-distortion limiter and vocal frequency forwardness designed for compact dynamic drivers and small speakers.',
      icon: Icons.speaker_rounded,
      eqBands: [-3.0, 1.0, 3.0, 4.0, 3.5, 3.0, 2.5, 2.0, 1.5, 1.0],
      bassBoost: 0.40,
      surround3D: 0.40,
      clarity: 0.95,
      tubeWarmth: 0.30,
      compressor: 0.85,
      reverbType: 'Studio',
      reverbMix: 0.10,
    ),
  ];

  static AcousticProfile getProfile(AcousticProfileType type) {
    return defaultProfiles.firstWhere(
      (p) => p.type == type,
      orElse: () => defaultProfiles.first,
    );
  }
}
