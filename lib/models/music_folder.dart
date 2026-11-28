import 'dart:io';
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
      String folderPath;
      String folderName;

      if (song.isAsset) {
        folderPath = 'assets/audio';
        folderName = 'AuraMix SoundLab (Bundled)';
      } else {
        try {
          final parent = File(song.path).parent;
          folderPath = parent.path;
          folderName = parent.path.split(Platform.pathSeparator).last;
          if (folderName.isEmpty) {
            folderName = song.album.isNotEmpty ? song.album : 'Storage';
          }
        } catch (_) {
          folderPath = song.album.isNotEmpty ? song.album : 'Device Audio';
          folderName = folderPath;
        }
      }

      folderMap.putIfAbsent(folderPath, () => []).add(song);
      folderNames[folderPath] = folderName;
    }

    final List<MusicFolder> list = [];
    folderMap.forEach((path, songsInFolder) {
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
