import 'song_item.dart';

class MusicFolder {
  final String name;
  final String path;
  final List<SongItem> songs;
  final bool isAsset;

  const MusicFolder({
    required this.name,
    required this.path,
    required this.songs,
    this.isAsset = false,
  });

  Duration get totalDuration =>
      songs.fold(Duration.zero, (prev, s) => prev + s.duration);

  /// Groups a list of songs into folders by parsing their file directory paths
  static List<MusicFolder> extractFolders(List<SongItem> songs) {
    final Map<String, List<SongItem>> folderMap = {};
    final Map<String, String> folderNames = {};

    for (final song in songs) {
      final folderPath = song.folderPath;
      final folderName = song.folderName;

      folderMap.putIfAbsent(folderPath, () => []).add(song);
      folderNames[folderPath] = folderName;
    }

    final List<MusicFolder> list = [];
    folderMap.forEach((path, songsInFolder) {
      // Sort songs within each folder alphabetically by song title A-Z
      songsInFolder.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

      list.add(MusicFolder(
        name: folderNames[path] ?? 'Music Folder',
        path: path,
        songs: songsInFolder,
        isAsset: path == 'assets/audio',
      ));
    });

    // Sort folders alphabetically, with device folders first and bundled at bottom
    list.sort((a, b) {
      if (a.isAsset && !b.isAsset) return 1;
      if (!a.isAsset && b.isAsset) return -1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return list;
  }
}
