class SongItem {
  final String id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String path;
  final bool isAsset;
  final String? albumArtUri;

  const SongItem({
    required this.id,
    required this.title,
    required this.artist,
    this.album = 'AuraMix Library',
    required this.duration,
    required this.path,
    this.isAsset = false,
    this.albumArtUri,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'album': album,
    'durationMs': duration.inMilliseconds,
    'path': path,
    'isAsset': isAsset,
    'albumArtUri': albumArtUri,
  };

  factory SongItem.fromJson(Map<String, dynamic> json) => SongItem(
    id: json['id'] as String,
    title: json['title'] as String? ?? 'Unknown Song',
    artist: json['artist'] as String? ?? 'Local Artist',
    album: json['album'] as String? ?? 'Local Storage',
    duration: Duration(milliseconds: json['durationMs'] as int? ?? 180000),
    path: json['path'] as String,
    isAsset: json['isAsset'] as bool? ?? false,
    albumArtUri: json['albumArtUri'] as String?,
  );

  String get folderPath {
    if (isAsset) return 'assets/audio';
    try {
      final normalized = path.replaceAll('\\', '/');
      final idx = normalized.lastIndexOf('/');
      if (idx > 0) return normalized.substring(0, idx);
    } catch (_) {}
    return album.isNotEmpty ? album : 'Device Audio';
  }

  String get folderName {
    if (isAsset) return 'AuraMix SoundLab (Bundled)';
    try {
      final fPath = folderPath;
      final idx = fPath.lastIndexOf('/');
      if (idx >= 0 && idx < fPath.length - 1) {
        final name = fPath.substring(idx + 1);
        if (name.isNotEmpty) return name;
      }
      return fPath;
    } catch (_) {}
    return album.isNotEmpty ? album : 'Device Audio';
  }
}
