import 'dart:convert';
import 'package:http/http.dart' as http;

class YoutubeService {
  static const String _apiKey = 'AIzaSyBdrNYJ7xvlUyVvdQ247E8ej8oHhavTdPk';
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3/videos';

  /// Fetches video details (title, description, thumbnails) using video ID.
  static Future<Map<String, dynamic>> getVideoDetails(String videoId) async {
    try {
      final url = Uri.parse('$_baseUrl?part=snippet&id=$videoId&key=$_apiKey');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      print('YouTube API Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'] != null && data['items'].isNotEmpty) {
          final snippet = data['items'][0]['snippet'];
          return {
            'success': true,
            'data': {
              'title': snippet['title'],
              'description': snippet['description'],
              'thumbnailUrl': snippet['thumbnails']?['high']?['url'] ?? 
                              snippet['thumbnails']?['default']?['url'],
            }
          };
        } else {
          return {'success': false, 'error': 'Video not found. Please check the ID.'};
        }
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['error']?['message'] ?? 'Unknown API error';
        print('YouTube API Error: $errorMessage');
        return {'success': false, 'error': errorMessage};
      }
    } catch (e) {
      print('Error fetching YouTube video details: $e');
      String error = e.toString();
      if (error.contains('SocketException') || error.contains('UnknownHostException')) {
        error = 'Network error: Cannot reach YouTube. Please check your internet connection.';
      }
      return {'success': false, 'error': error};
    }
  }
}
