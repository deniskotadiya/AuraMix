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
}
