import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dps_control.dart';
import 'dps_engine.dart';
import 'auth_service.dart';

enum PresetSortOption {
  mostLiked,
  mostPlays,
  newest,
  alphabetical,
}

enum PresetVisibilityFilter {
  all,
  publicOnly,
  privateOnly,
  likedOnly,
}

class PresetRepository extends ChangeNotifier {
  PresetRepository._();
  static final PresetRepository instance = PresetRepository._();

  List<DPSPreset> _presets = [];
  bool _loaded = false;

  List<DPSPreset> get presets => List.unmodifiable(_presets);

  Future<void> initialize() async {
    if (_loaded) return;
    _presets = List.from(DPSEngine.defaultPresets);
    await _loadCustomPresets();
    _loaded = true;
    notifyListeners();
  }

  Future<void> _loadCustomPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('auramix_custom_presets') ?? [];
    for (final raw in jsonList) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final preset = DPSPreset.fromJson(map);
        // Avoid duplicate ID if defaults overlap
        if (!_presets.any((p) => p.id == preset.id)) {
          _presets.add(preset);
        }
      } catch (e) {
        debugPrint('[PresetRepository] Error parsing custom preset: $e');
      }
    }
  }

  Future<void> _saveCustomPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final customList = _presets.where((p) => !DPSEngine.defaultPresets.any((d) => d.id == p.id)).toList();
    final encoded = customList.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList('auramix_custom_presets', encoded);
  }

  /// Create a new custom DPS preset
  Future<DPSPreset> createPreset({
    required String title,
    required String description,
    required String category,
    required bool isPublic,
    required List<double> eqBands,
    required double bassBoost,
    required double surround3D,
    required double clarity,
    required double tubeWarmth,
    required double compressor,
    required String reverbType,
    required double reverbMix,
    required double pitchShift,
    required double speed,
    List<SongRecommendation>? recommendedSongs,
  }) async {
    final currentUser = AuthService.instance.currentUser;
    final creatorName = currentUser?.displayName ?? 'Local Creator';

    final newPreset = DPSPreset(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      description: description.trim(),
      creator: creatorName,
      isPublic: isPublic,
      category: category,
      isPremium: false,
      likes: 1,
      dislikes: 0,
      plays: 1,
      eqBands: eqBands,
      bassBoost: bassBoost,
      surround3D: surround3D,
      clarity: clarity,
      tubeWarmth: tubeWarmth,
      compressor: compressor,
      reverbType: reverbType,
      reverbMix: reverbMix,
      pitchShift: pitchShift,
      speed: speed,
      recommendedSongs: recommendedSongs ?? [],
    );

    _presets.insert(0, newPreset);
    await _saveCustomPresets();
    notifyListeners();
    return newPreset;
  }

  /// Like or Dislike interaction
  Future<void> toggleReaction(String presetId, String reaction) async {
    final index = _presets.indexWhere((p) => p.id == presetId);
    if (index == -1) return;

    final p = _presets[index];
    int newLikes = p.likes;
    int newDislikes = p.dislikes;
    String? finalReaction;

    if (p.userReaction == reaction) {
      // Toggle off
      if (reaction == 'like') newLikes = (newLikes - 1).clamp(0, 999999);
      if (reaction == 'dislike') newDislikes = (newDislikes - 1).clamp(0, 999999);
      finalReaction = null;
    } else {
      // Switch or set
      if (p.userReaction == 'like') newLikes = (newLikes - 1).clamp(0, 999999);
      if (p.userReaction == 'dislike') newDislikes = (newDislikes - 1).clamp(0, 999999);

      if (reaction == 'like') newLikes += 1;
      if (reaction == 'dislike') newDislikes += 1;
      finalReaction = reaction;
    }

    _presets[index] = p.copyWith(
      likes: newLikes,
      dislikes: newDislikes,
      userReaction: finalReaction,
    );
    await _saveCustomPresets();
    notifyListeners();
  }

  /// Add a song recommendation to an existing preset
  Future<void> addSongRecommendation(String presetId, SongRecommendation song) async {
    final index = _presets.indexWhere((p) => p.id == presetId);
    if (index == -1) return;

    final p = _presets[index];
    final updatedSongs = List<SongRecommendation>.from(p.recommendedSongs)..add(song);
    _presets[index] = p.copyWith(recommendedSongs: updatedSongs);
    await _saveCustomPresets();
    notifyListeners();
  }

  /// Filter & Sort presets
  List<DPSPreset> getFilteredPresets({
    String query = '',
    String category = 'All',
    PresetVisibilityFilter visibility = PresetVisibilityFilter.all,
    PresetSortOption sortOption = PresetSortOption.mostLiked,
  }) {
    final currentUserName = AuthService.instance.currentUser?.displayName;

    var result = _presets.where((p) {
      // Search query
      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        final matches = p.title.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q) ||
            p.creator.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q);
        if (!matches) return false;
      }

      // Category filter
      if (category != 'All' && p.category != category) {
        return false;
      }

      // Visibility filter
      switch (visibility) {
        case PresetVisibilityFilter.all:
          // Show public presets, PLUS user's own private presets
          if (!p.isPublic && (currentUserName == null || p.creator != currentUserName)) {
            return false;
          }
          break;
        case PresetVisibilityFilter.publicOnly:
          if (!p.isPublic) return false;
          break;
        case PresetVisibilityFilter.privateOnly:
          if (p.isPublic) return false;
          if (currentUserName != null && p.creator != currentUserName) return false;
          break;
        case PresetVisibilityFilter.likedOnly:
          if (p.userReaction != 'like') return false;
          break;
      }

      return true;
    }).toList();

    // Sorting
    switch (sortOption) {
      case PresetSortOption.mostLiked:
        result.sort((a, b) => b.likes.compareTo(a.likes));
        break;
      case PresetSortOption.mostPlays:
        result.sort((a, b) => b.plays.compareTo(a.plays));
        break;
      case PresetSortOption.newest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case PresetSortOption.alphabetical:
        result.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }

    return result;
  }
}
