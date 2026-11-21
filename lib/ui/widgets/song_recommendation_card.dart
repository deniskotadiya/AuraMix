import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/dps_control.dart';
import '../../core/preset_repository.dart';

class SongRecommendationCard extends StatelessWidget {
  final String presetId;
  final List<SongRecommendation> recommendations;

  const SongRecommendationCard({
    super.key,
    required this.presetId,
    required this.recommendations,
  });

  void _showAddSongDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final artistCtrl = TextEditingController();
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14172B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.neonCyan.withAlpha(90)),
        ),
        title: const Row(
          children: [
            Icon(Icons.queue_music_rounded, color: AppTheme.neonCyan),
            SizedBox(width: 8),
            Text('Suggest a Song', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tell the community which song sounds best with this DPS effect!',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Song Title',
                  labelStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: Colors.white.withAlpha(15),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: artistCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Artist Name',
                  labelStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: Colors.white.withAlpha(15),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: commentCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Why does it sound best? (e.g. Bass drop, Vocal purity)',
                  labelStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: Colors.white.withAlpha(15),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty) {
                final rec = SongRecommendation(
                  title: titleCtrl.text.trim(),
                  artist: artistCtrl.text.trim().isEmpty ? 'Unknown Artist' : artistCtrl.text.trim(),
                  comment: commentCtrl.text.trim(),
                );
                PresetRepository.instance.addSongRecommendation(presetId, rec);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Song suggested to community!')),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.neonCyan,
              foregroundColor: Colors.black,
            ),
            child: const Text('Add Song', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131626),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.headphones_rounded, size: 18, color: AppTheme.neonCyan),
                  SizedBox(width: 8),
                  Text(
                    'Best Songs For This Control',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppTheme.neonCyan, size: 20),
                tooltip: 'Suggest a Song',
                onPressed: () => _showAddSongDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (recommendations.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No songs suggested yet. Be the first to recommend a track!',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            )
          else
            Column(
              children: recommendations.map((r) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppTheme.neonPurple.withAlpha(50),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.music_note_rounded, color: AppTheme.neonPurple, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                            ),
                            Text(
                              r.artist,
                              style: const TextStyle(fontSize: 11, color: Colors.white70),
                            ),
                            if (r.comment.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                '"${r.comment}"',
                                style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppTheme.neonCyan),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
