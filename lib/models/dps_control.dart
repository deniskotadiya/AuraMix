
class SongRecommendation {
  final String title;
  final String artist;
  final String comment;
  final String addedBy;

  const SongRecommendation({
    required this.title,
    required this.artist,
    this.comment = '',
    this.addedBy = 'Community',
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'artist': artist,
    'comment': comment,
    'addedBy': addedBy,
  };

  factory SongRecommendation.fromJson(Map<String, dynamic> json) => SongRecommendation(
    title: json['title'] as String? ?? 'Untitled Track',
    artist: json['artist'] as String? ?? 'Unknown Artist',
    comment: json['comment'] as String? ?? '',
    addedBy: json['addedBy'] as String? ?? 'Community',
  );
}

class DPSPreset {
  final String id;
  final String title;
  final String description;
  final String creator;
  final bool isPublic;
  int likes;
  int dislikes;
  int plays;
  final bool isPremium;
  final String category;
  final DateTime createdAt;
  
  // 10-Band EQ in dB (-12.0 to +12.0)
  // Bands: [31Hz, 63Hz, 125Hz, 250Hz, 500Hz, 1kHz, 2kHz, 4kHz, 8kHz, 16kHz]
  final List<double> eqBands;
  
  // DSP Effects (0.0 to 1.0)
  final double bassBoost;       // Sub-bass punch
  final double surround3D;      // Spatial 3D expander
  final double clarity;         // High-freq exciter / vocal crispness
  final double tubeWarmth;      // Analog tube saturation & harmonics
  final double compressor;      // Dynamic normalizer & punch
  final String reverbType;      // Off, Studio, Club, Arena, Cathedral
  final double reverbMix;       // 0.0 to 1.0
  final double pitchShift;      // -12 to +12 semitones
  final double speed;           // 0.5 to 2.0x
  
  // Stem & Instrument Level Isolators (-6.0 dB to +6.0 dB, 0.0 = neutral/flat)
  final double vocalGain;  // Vocals & Lyrics / Words Presence (1kHz - 4kHz)
  final double musicGain;  // Instruments, Guitars, Synths & Keys (250Hz - 1kHz)
  final double bassGain;   // Rhythm, Kicks, 808s & Bass (31Hz - 125Hz)
  final double trebleGain; // Air, Cymbals & Acoustic Ambience (8kHz - 16kHz)
  
  final List<SongRecommendation> recommendedSongs;
  String? userReaction; // 'like', 'dislike', or null

  DPSPreset({
    required this.id,
    required this.title,
    required this.description,
    required this.creator,
    this.isPublic = true,
    this.likes = 0,
    this.dislikes = 0,
    this.plays = 0,
    this.isPremium = false,
    this.category = 'General',
    DateTime? createdAt,
    List<double>? eqBands,
    this.bassBoost = 0.5,
    this.surround3D = 0.4,
    this.clarity = 0.5,
    this.tubeWarmth = 0.3,
    this.compressor = 0.4,
    this.reverbType = 'Off',
    this.reverbMix = 0.2,
    this.pitchShift = 0.0,
    this.speed = 1.0,
    this.vocalGain = 0.0,
    this.musicGain = 0.0,
    this.bassGain = 0.0,
    this.trebleGain = 0.0,
    List<SongRecommendation>? recommendedSongs,
    this.userReaction,
  }) : createdAt = createdAt ?? DateTime.now(),
       eqBands = eqBands ?? List.filled(10, 0.0),
       recommendedSongs = recommendedSongs ?? [];

  DPSPreset copyWith({
    String? id,
    String? title,
    String? description,
    String? creator,
    bool? isPublic,
    int? likes,
    int? dislikes,
    int? plays,
    bool? isPremium,
    String? category,
    DateTime? createdAt,
    List<double>? eqBands,
    double? bassBoost,
    double? surround3D,
    double? clarity,
    double? tubeWarmth,
    double? compressor,
    String? reverbType,
    double? reverbMix,
    double? pitchShift,
    double? speed,
    double? vocalGain,
    double? musicGain,
    double? bassGain,
    double? trebleGain,
    List<SongRecommendation>? recommendedSongs,
    String? userReaction,
  }) {
    return DPSPreset(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      creator: creator ?? this.creator,
      isPublic: isPublic ?? this.isPublic,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      plays: plays ?? this.plays,
      isPremium: isPremium ?? this.isPremium,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      eqBands: eqBands ?? List<double>.from(this.eqBands),
      bassBoost: bassBoost ?? this.bassBoost,
      surround3D: surround3D ?? this.surround3D,
      clarity: clarity ?? this.clarity,
      tubeWarmth: tubeWarmth ?? this.tubeWarmth,
      compressor: compressor ?? this.compressor,
      reverbType: reverbType ?? this.reverbType,
      reverbMix: reverbMix ?? this.reverbMix,
      pitchShift: pitchShift ?? this.pitchShift,
      speed: speed ?? this.speed,
      vocalGain: vocalGain ?? this.vocalGain,
      musicGain: musicGain ?? this.musicGain,
      bassGain: bassGain ?? this.bassGain,
      trebleGain: trebleGain ?? this.trebleGain,
      recommendedSongs: recommendedSongs ?? List<SongRecommendation>.from(this.recommendedSongs),
      userReaction: userReaction ?? this.userReaction,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'creator': creator,
    'isPublic': isPublic,
    'likes': likes,
    'dislikes': dislikes,
    'plays': plays,
    'isPremium': isPremium,
    'category': category,
    'createdAt': createdAt.toIso8601String(),
    'eqBands': eqBands,
    'bassBoost': bassBoost,
    'surround3D': surround3D,
    'clarity': clarity,
    'tubeWarmth': tubeWarmth,
    'compressor': compressor,
    'reverbType': reverbType,
    'reverbMix': reverbMix,
    'pitchShift': pitchShift,
    'speed': speed,
    'vocalGain': vocalGain,
    'musicGain': musicGain,
    'bassGain': bassGain,
    'trebleGain': trebleGain,
    'recommendedSongs': recommendedSongs.map((s) => s.toJson()).toList(),
    'userReaction': userReaction,
  };

  factory DPSPreset.fromJson(Map<String, dynamic> json) {
    return DPSPreset(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled Preset',
      description: json['description'] as String? ?? '',
      creator: json['creator'] as String? ?? 'AuraMix SoundLab',
      isPublic: json['isPublic'] as bool? ?? true,
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      dislikes: (json['dislikes'] as num?)?.toInt() ?? 0,
      plays: (json['plays'] as num?)?.toInt() ?? 0,
      isPremium: json['isPremium'] as bool? ?? false,
      category: json['category'] as String? ?? 'General',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      eqBands: (json['eqBands'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          List.filled(10, 0.0),
      bassBoost: (json['bassBoost'] as num?)?.toDouble() ?? 0.5,
      surround3D: (json['surround3D'] as num?)?.toDouble() ?? 0.4,
      clarity: (json['clarity'] as num?)?.toDouble() ?? 0.5,
      tubeWarmth: (json['tubeWarmth'] as num?)?.toDouble() ?? 0.3,
      compressor: (json['compressor'] as num?)?.toDouble() ?? 0.4,
      reverbType: json['reverbType'] as String? ?? 'Off',
      reverbMix: (json['reverbMix'] as num?)?.toDouble() ?? 0.2,
      pitchShift: (json['pitchShift'] as num?)?.toDouble() ?? 0.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
      vocalGain: (json['vocalGain'] as num?)?.toDouble() ?? 0.0,
      musicGain: (json['musicGain'] as num?)?.toDouble() ?? 0.0,
      bassGain: (json['bassGain'] as num?)?.toDouble() ?? 0.0,
      trebleGain: (json['trebleGain'] as num?)?.toDouble() ?? 0.0,
      recommendedSongs: (json['recommendedSongs'] as List<dynamic>?)
              ?.map((e) => SongRecommendation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      userReaction: json['userReaction'] as String?,
    );
  }
}
