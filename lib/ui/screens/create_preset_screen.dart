import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/preset_repository.dart';
import '../../core/dps_engine.dart';
import '../../models/dps_control.dart';

class CreatePresetScreen extends StatefulWidget {
  final DPSPreset? initialPreset;

  const CreatePresetScreen({super.key, this.initialPreset});

  @override
  State<CreatePresetScreen> createState() => _CreatePresetScreenState();
}

class _CreatePresetScreenState extends State<CreatePresetScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _recSongTitleCtrl = TextEditingController();
  final _recSongArtistCtrl = TextEditingController();
  final _recSongCommentCtrl = TextEditingController();

  String _category = 'Car Audio';
  bool _isPublic = true;

  late List<double> _eqBands;
  late double _bassBoost;
  late double _surround3D;
  late double _clarity;
  late double _tubeWarmth;
  late double _compressor;
  late String _reverbType;
  late double _speed;

  @override
  void initState() {
    super.initState();
    final p = widget.initialPreset ?? DPSEngine.instance.activePreset;
    _titleCtrl.text = widget.initialPreset != null ? '${p.title} Custom' : '';
    _descCtrl.text = p.description;
    _category = p.category;
    _eqBands = List<double>.from(p.eqBands);
    _bassBoost = p.bassBoost;
    _surround3D = p.surround3D;
    _clarity = p.clarity;
    _tubeWarmth = p.tubeWarmth;
    _compressor = p.compressor;
    _reverbType = p.reverbType;
    _speed = p.speed;
  }

  Future<void> _savePreset() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a preset title')),
      );
      return;
    }

    final List<SongRecommendation> initialSongs = [];
    if (_recSongTitleCtrl.text.trim().isNotEmpty) {
      initialSongs.add(
        SongRecommendation(
          title: _recSongTitleCtrl.text.trim(),
          artist: _recSongArtistCtrl.text.trim().isEmpty ? 'Various Artists' : _recSongArtistCtrl.text.trim(),
          comment: _recSongCommentCtrl.text.trim(),
        ),
      );
    }

    final newPreset = await PresetRepository.instance.createPreset(
      title: title,
      description: _descCtrl.text.trim().isEmpty ? 'Custom tuned DPS audio preset.' : _descCtrl.text.trim(),
      category: _category,
      isPublic: _isPublic,
      eqBands: _eqBands,
      bassBoost: _bassBoost,
      surround3D: _surround3D,
      clarity: _clarity,
      tubeWarmth: _tubeWarmth,
      compressor: _compressor,
      reverbType: _reverbType,
      reverbMix: 0.2,
      pitchShift: 0.0,
      speed: _speed,
      recommendedSongs: initialSongs,
    );

    // Automatically load into DPS engine
    DPSEngine.instance.loadPreset(newPreset);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isPublic
                ? '🎉 "$title" published to Community Sound Lab!'
                : '🔒 "$title" saved to your Private Presets!',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create DPS Preset'),
        actions: [
          TextButton(
            onPressed: _savePreset,
            child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.neonCyan)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Description
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Preset Title (e.g. Bass Cannon, Night Cruise)',
                labelStyle: const TextStyle(color: Colors.white60),
                filled: true,
                fillColor: const Color(0xFF131526),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Sound Description / Acoustic profile',
                labelStyle: const TextStyle(color: Colors.white60),
                filled: true,
                fillColor: const Color(0xFF131526),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 18),

            // Category & Privacy Switch
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassBoxDecoration(radius: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Category:', style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                        value: _category,
                        dropdownColor: const Color(0xFF131526),
                        underline: const SizedBox(),
                        items: ['Car Audio', 'Bass Heavy', 'Acoustic', 'Vocal', 'General'].map((c) {
                          return DropdownMenuItem(value: c, child: Text(c));
                        }).toList(),
                        onChanged: (val) => setState(() => _category = val ?? _category),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12),
                  // Privacy Selection (Public vs Private)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isPublic ? Icons.public : Icons.lock_outline,
                                color: _isPublic ? AppTheme.carNeonGreen : Colors.orangeAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isPublic ? 'Public Preset' : 'Private Preset',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isPublic
                                ? 'Shared with all community drivers'
                                : 'Visible only on this device / account',
                            style: const TextStyle(fontSize: 11, color: Colors.white54),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isPublic,
                        activeThumbColor: AppTheme.carNeonGreen,
                        onChanged: (val) => setState(() => _isPublic = val),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // DSP Knobs Sliders
            const Text(
              'DSP PARAMETERS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppTheme.neonCyan),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassBoxDecoration(radius: 16),
              child: Column(
                children: [
                  _ParameterRow(
                    label: 'Sub-Bass Boost',
                    value: _bassBoost,
                    onChanged: (v) => setState(() => _bassBoost = v),
                    color: AppTheme.carNeonGreen,
                  ),
                  _ParameterRow(
                    label: '3D Surround Width',
                    value: _surround3D,
                    onChanged: (v) => setState(() => _surround3D = v),
                    color: AppTheme.neonCyan,
                  ),
                  _ParameterRow(
                    label: 'Vocal Clarity',
                    value: _clarity,
                    onChanged: (v) => setState(() => _clarity = v),
                    color: AppTheme.neonPurple,
                  ),
                  _ParameterRow(
                    label: 'Tube Amp Warmth',
                    value: _tubeWarmth,
                    onChanged: (v) => setState(() => _tubeWarmth = v),
                    color: AppTheme.carAmber,
                  ),
                  _ParameterRow(
                    label: 'Dynamic Compressor',
                    value: _compressor,
                    onChanged: (v) => setState(() => _compressor = v),
                    color: AppTheme.neonPink,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Optional Recommended Song
            const Text(
              'SUGGEST A MATCHING SONG (OPTIONAL)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppTheme.neonCyan),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassBoxDecoration(radius: 16),
              child: Column(
                children: [
                  TextField(
                    controller: _recSongTitleCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Song Title (e.g. Blinding Lights)',
                      labelStyle: const TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: Colors.white.withAlpha(10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _recSongArtistCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Artist',
                      labelStyle: const TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: Colors.white.withAlpha(10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _recSongCommentCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Why this song sounds best with this preset',
                      labelStyle: const TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: Colors.white.withAlpha(10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save Action Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _savePreset,
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('CREATE & ACTIVATE PRESET', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonCyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParameterRow extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final Color color;

  const _ParameterRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: color,
                thumbColor: Colors.white,
                trackHeight: 3,
              ),
              child: Slider(
                value: value,
                min: 0.0,
                max: 1.0,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
