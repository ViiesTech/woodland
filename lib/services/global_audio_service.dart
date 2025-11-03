import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../admin_panel/models/book_model.dart';

class GlobalAudioService extends ChangeNotifier {
  static final GlobalAudioService _instance = GlobalAudioService._internal();
  factory GlobalAudioService() => _instance;
  GlobalAudioService._internal();

  AudioPlayer? _audioPlayer;
  BookModel? _currentBook;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  int _currentChapterIndex = 0;
  bool _isVisible = false;

  AudioPlayer? get audioPlayer => _audioPlayer;
  BookModel? get currentBook => _currentBook;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  int get currentChapterIndex => _currentChapterIndex;
  bool get isVisible => _isVisible;

  void initialize() {
    // Initialize will be called from DashboardScreen
    // AudioPlayer will be set from ListenScreen
  }

  void setAudioPlayer(AudioPlayer player) {
    _audioPlayer = player;
    
    // Set up listeners
    _audioPlayer!.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    _audioPlayer!.onPositionChanged.listen((position) {
      _position = position;
      notifyListeners();
    });

    _audioPlayer!.onDurationChanged.listen((duration) {
      _duration = duration;
      notifyListeners();
    });
  }

  void updatePlayingState(bool isPlaying) {
    _isPlaying = isPlaying;
    notifyListeners();
  }

  void setCurrentBook(BookModel book, int chapterIndex) {
    _currentBook = book;
    _currentChapterIndex = chapterIndex;
    _isVisible = true;
    notifyListeners();
  }

  Future<void> playPause() async {
    if (_audioPlayer == null) return;
    
    if (_isPlaying) {
      await _audioPlayer!.pause();
    } else {
      await _audioPlayer!.resume();
    }
  }

  void hideOverlay() {
    _isVisible = false;
    notifyListeners();
  }

  Future<void> stopAndClear() async {
    if (_audioPlayer != null) {
      await _audioPlayer!.stop();
    }
    _currentBook = null;
    _isPlaying = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    _currentChapterIndex = 0;
    _isVisible = false;
    notifyListeners();
  }

  void showOverlay() {
    if (_currentBook != null) {
      _isVisible = true;
      notifyListeners();
    }
  }

  void updateChapterIndex(int index) {
    _currentChapterIndex = index;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }
}

