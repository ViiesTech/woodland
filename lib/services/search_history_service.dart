import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const String _key = 'ebook_recent_searches';
  static const int _maxRecentSearches = 5;

  /// Add a search query to recent searches
  static Future<void> addSearchQuery(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> searches = getRecentSearchesSync(prefs);
      
      // Remove if already exists (to move to top)
      searches.remove(query.trim());
      
      // Add to beginning
      searches.insert(0, query.trim());
      
      // Keep only the most recent 5
      if (searches.length > _maxRecentSearches) {
        searches = searches.sublist(0, _maxRecentSearches);
      }
      
      // Save to SharedPreferences
      await prefs.setStringList(_key, searches);
    } catch (e) {
      print('Error saving search query: $e');
    }
  }

  /// Get recent searches
  static Future<List<String>> getRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return getRecentSearchesSync(prefs);
    } catch (e) {
      print('Error getting recent searches: $e');
      return [];
    }
  }

  /// Get recent searches synchronously (helper method)
  static List<String> getRecentSearchesSync(SharedPreferences prefs) {
    try {
      return prefs.getStringList(_key) ?? [];
    } catch (e) {
      print('Error getting recent searches: $e');
      return [];
    }
  }

  /// Clear all recent searches
  static Future<void> clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      print('Error clearing recent searches: $e');
    }
  }
}

