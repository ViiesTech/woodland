import 'package:shared_preferences/shared_preferences.dart';

/// Recently opened Library → Videos (YouTube) ids, same persistence pattern as
/// [SearchHistoryService].
class LibraryVideoRecentService {
  static const String _key = 'library_video_recent_watch_ids';
  static const int _max = 5;

  static Future<List<String>> getRecentVideoIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_key) ?? [];
    } catch (e) {
      print('Error getting recent video ids: $e');
      return [];
    }
  }

  static Future<void> addRecentVideoId(String videoId) async {
    if (videoId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = List<String>.from(prefs.getStringList(_key) ?? []);
      list.remove(videoId);
      list.insert(0, videoId);
      if (list.length > _max) {
        list.removeRange(_max, list.length);
      }
      await prefs.setStringList(_key, list);
    } catch (e) {
      print('Error saving recent video id: $e');
    }
  }

  static Future<void> clearRecent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      print('Error clearing recent videos: $e');
    }
  }
}
