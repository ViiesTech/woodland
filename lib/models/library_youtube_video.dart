/// Curated book-related YouTube entries. Replace [videoId] with your own
/// channel or playlist videos as needed.
class LibraryYoutubeVideo {
  const LibraryYoutubeVideo({
    required this.videoId,
    required this.title,
    required this.description,
  });

  final String videoId;
  final String title;
  final String description;

  Uri get watchUri =>
      Uri.parse('https://www.youtube.com/watch?v=$videoId');

  String get thumbnailUrl =>
      'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
}

/// Default catalog for the Library → Videos tab (order = Featured / grid).
const List<LibraryYoutubeVideo> kLibraryYoutubeVideos = [
  LibraryYoutubeVideo(
    videoId: 'MSYw502dJNY',
    title: 'How and Why We Read',
    description: 'Crash Course Literature · Why stories matter',
  ),
  LibraryYoutubeVideo(
    videoId: 'muuWRKYi09s',
    title: 'Why Reading Matters',
    description: 'Rita Carter · TEDxCluj',
  ),
  LibraryYoutubeVideo(
    videoId: 'wznroZvpVHU',
    title: 'The Power of Reading',
    description: 'Alexia Safieh · TEDxActonAcademyGuatemala',
  ),
  LibraryYoutubeVideo(
    videoId: 'bXjAMAa5uI4',
    title: 'Why Should You Read Shakespeare?',
    description: 'The School of Life',
  ),
  LibraryYoutubeVideo(
    videoId: 'NaG9QiXNlIA',
    title: 'The Pleasure of Reading',
    description: 'Literacy and learning · TED-Ed style',
  ),
];
