class LibraryYoutubeVideo {
  const LibraryYoutubeVideo({
    required this.id,
    required this.videoId,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    this.isPublished = true,
  });

  final String id;
  final String videoId;
  final String title;
  final String description;
  final String thumbnailUrl;
  final bool isPublished;

  Uri get watchUri =>
      Uri.parse('https://www.youtube.com/watch?v=$videoId');

  Map<String, dynamic> toMap() {
    return {
      'videoId': videoId,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'isPublished': isPublished,
    };
  }

  factory LibraryYoutubeVideo.fromMap(Map<String, dynamic> map, String id) {
    return LibraryYoutubeVideo(
      id: id,
      videoId: map['videoId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? 'https://img.youtube.com/vi/${map['videoId']}/hqdefault.jpg',
      isPublished: map['isPublished'] ?? true,
    );
  }
}

