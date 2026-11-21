import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/preset_repository.dart';
import '../../core/dps_engine.dart';
import '../../core/auth_service.dart';
import '../../models/dps_control.dart';
import '../widgets/premium_unlock_dialog.dart';
import '../widgets/song_recommendation_card.dart';
import 'create_preset_screen.dart';

class CommunityPresetsScreen extends StatefulWidget {
  const CommunityPresetsScreen({super.key});

  @override
  State<CommunityPresetsScreen> createState() => _CommunityPresetsScreenState();
}

class _CommunityPresetsScreenState extends State<CommunityPresetsScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  PresetVisibilityFilter _visibility = PresetVisibilityFilter.all;
  PresetSortOption _sortOption = PresetSortOption.mostLiked;

  final List<String> _categories = [
    'All',
    'Car Audio',
    'Bass Heavy',
    'Acoustic',
    'Vocal',
    'General',
  ];

  void _applyPreset(BuildContext context, DPSPreset preset) {
    if (preset.isPremium && !AuthService.instance.isControlUnlocked('preset_${preset.id}')) {
      PremiumUnlockDialog.show(
        context: context,
        controlKey: 'preset_${preset.id}',
        controlName: preset.title,
        description: '${preset.description}\nWatch a quick ad to use this premium community sound profile for 1 session or get VIP!',
        onUnlocked: () {
          DPSEngine.instance.loadPreset(preset);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Applied "${preset.title}" DPS effect!')),
          );
        },
      );
    } else {
      DPSEngine.instance.loadPreset(preset);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Applied "${preset.title}" DPS effect!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PresetRepository.instance,
      builder: (context, _) {
        final presets = PresetRepository.instance.getFilteredPresets(
          query: _searchQuery,
          category: _selectedCategory,
          visibility: _visibility,
          sortOption: _sortOption,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Community Sound Lab'),
            actions: [
              // Sort Menu
              PopupMenuButton<PresetSortOption>(
                icon: const Icon(Icons.sort_rounded, color: AppTheme.neonCyan),
                tooltip: 'Sort Presets',
                onSelected: (opt) => setState(() => _sortOption = opt),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: PresetSortOption.mostLiked,
                    child: Text('Most Liked 👍'),
                  ),
                  const PopupMenuItem(
                    value: PresetSortOption.mostPlays,
                    child: Text('Most Plays 🔥'),
                  ),
                  const PopupMenuItem(
                    value: PresetSortOption.newest,
                    child: Text('Newest First ⚡'),
                  ),
                  const PopupMenuItem(
                    value: PresetSortOption.alphabetical,
                    child: Text('Alphabetical (A-Z)'),
                  ),
                ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CreatePresetScreen(initialPreset: DPSEngine.instance.activePreset),
                ),
              );
            },
            backgroundColor: AppTheme.neonCyan,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Preset', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: Column(
            children: [
              // Search Input
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search sound controls, creators, songs...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.neonCyan),
                    filled: true,
                    fillColor: const Color(0xFF131526),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withAlpha(20)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.neonCyan),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),

              // Visibility Segment Chips (All, Public, Private, Liked)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    _FilterChipItem(
                      label: 'All Presets',
                      isSelected: _visibility == PresetVisibilityFilter.all,
                      onTap: () => setState(() => _visibility = PresetVisibilityFilter.all),
                    ),
                    const SizedBox(width: 8),
                    _FilterChipItem(
                      label: 'Public Feed 🌍',
                      isSelected: _visibility == PresetVisibilityFilter.publicOnly,
                      onTap: () => setState(() => _visibility = PresetVisibilityFilter.publicOnly),
                    ),
                    const SizedBox(width: 8),
                    _FilterChipItem(
                      label: 'My Private 🔒',
                      isSelected: _visibility == PresetVisibilityFilter.privateOnly,
                      onTap: () => setState(() => _visibility = PresetVisibilityFilter.privateOnly),
                    ),
                    const SizedBox(width: 8),
                    _FilterChipItem(
                      label: 'Liked ❤️',
                      isSelected: _visibility == PresetVisibilityFilter.likedOnly,
                      onTap: () => setState(() => _visibility = PresetVisibilityFilter.likedOnly),
                    ),
                  ],
                ),
              ),

              // Category Filter Horizontal List
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (ctx, idx) {
                    final cat = _categories[idx];
                    final isSel = cat == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat, style: TextStyle(fontSize: 12, color: isSel ? Colors.black : Colors.white70)),
                        selected: isSel,
                        selectedColor: AppTheme.neonCyan,
                        backgroundColor: const Color(0xFF16192E),
                        side: BorderSide(color: isSel ? AppTheme.neonCyan : Colors.white12),
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),

              // Presets Feed List
              Expanded(
                child: presets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.graphic_eq_rounded, size: 54, color: Colors.white.withAlpha(30)),
                            const SizedBox(height: 12),
                            const Text(
                              'No DPS Presets Found',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Try adjusting filters or tap + Create Preset to make your own!',
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 90),
                        itemCount: presets.length,
                        itemBuilder: (ctx, idx) {
                          final p = presets[idx];
                          final isActive = DPSEngine.instance.activePreset.id == p.id;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF131526),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isActive ? AppTheme.neonCyan : Colors.white.withAlpha(20),
                                width: isActive ? 1.5 : 1,
                              ),
                              boxShadow: [
                                if (isActive)
                                  BoxShadow(
                                    color: AppTheme.neonCyan.withAlpha(50),
                                    blurRadius: 14,
                                    spreadRadius: 1,
                                  ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Title & Category Badge
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    p.title,
                                                    style: const TextStyle(
                                                      fontSize: 17,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (p.isPremium) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.carAmber.withAlpha(40),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: const Text(
                                                      'VIP',
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w900,
                                                        color: AppTheme.carAmber,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'by ${p.creator} · ${p.category}',
                                              style: const TextStyle(fontSize: 12, color: Colors.white54),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Public / Private Indicator
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: p.isPublic ? AppTheme.carNeonGreen.withAlpha(25) : Colors.orangeAccent.withAlpha(25),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              p.isPublic ? Icons.public : Icons.lock_outline,
                                              size: 12,
                                              color: p.isPublic ? AppTheme.carNeonGreen : Colors.orangeAccent,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              p.isPublic ? 'Public' : 'Private',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: p.isPublic ? AppTheme.carNeonGreen : Colors.orangeAccent,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Description
                                  Text(
                                    p.description,
                                    style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.3),
                                  ),
                                  const SizedBox(height: 12),

                                  // Mini DSP Specs Summary Pills
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _SpecPill(label: 'Bass', value: '${(p.bassBoost * 100).toInt()}%', color: AppTheme.carNeonGreen),
                                      _SpecPill(label: '3D Spatial', value: '${(p.surround3D * 100).toInt()}%', color: AppTheme.neonCyan),
                                      _SpecPill(label: 'Clarity', value: '${(p.clarity * 100).toInt()}%', color: AppTheme.neonPurple),
                                      _SpecPill(label: 'Tube', value: '${(p.tubeWarmth * 100).toInt()}%', color: AppTheme.carAmber),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  // Best Songs recommendations section
                                  SongRecommendationCard(
                                    presetId: p.id,
                                    recommendations: p.recommendedSongs,
                                  ),
                                  const SizedBox(height: 12),

                                  // Bottom Row: Like, Dislike, Plays, Apply Button
                                  Row(
                                    children: [
                                      // Like button
                                      InkWell(
                                        onTap: () => PresetRepository.instance.toggleReaction(p.id, 'like'),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          child: Row(
                                            children: [
                                              Icon(
                                                p.userReaction == 'like' ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                                                size: 16,
                                                color: p.userReaction == 'like' ? AppTheme.neonCyan : Colors.white60,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${p.likes}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: p.userReaction == 'like' ? AppTheme.neonCyan : Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),

                                      // Dislike button
                                      InkWell(
                                        onTap: () => PresetRepository.instance.toggleReaction(p.id, 'dislike'),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          child: Row(
                                            children: [
                                              Icon(
                                                p.userReaction == 'dislike' ? Icons.thumb_down_alt_rounded : Icons.thumb_down_alt_outlined,
                                                size: 16,
                                                color: p.userReaction == 'dislike' ? AppTheme.neonPink : Colors.white60,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${p.dislikes}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: p.userReaction == 'dislike' ? AppTheme.neonPink : Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const Spacer(),

                                      // Apply Button
                                      FilledButton.icon(
                                        onPressed: () => _applyPreset(context, p),
                                        icon: Icon(
                                          isActive ? Icons.check_circle_rounded : Icons.play_arrow_rounded,
                                          size: 16,
                                        ),
                                        label: Text(isActive ? 'ACTIVE' : 'APPLY DPS'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: isActive ? AppTheme.carNeonGreen : AppTheme.neonCyan,
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.neonCyan.withAlpha(40) : const Color(0xFF14172B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.neonCyan : Colors.white12,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppTheme.neonCyan : Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _SpecPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SpecPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
