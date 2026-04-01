import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;
  double _speed = 1.0;
  int _currentParagraph = 0;
  List<String> _paragraphs = [];
  void Function(int index)? onParagraphChanged;
  void Function(bool playing)? onPlayingChanged;

  bool get isPlaying => _isPlaying;
  double get speed => _speed;
  int get currentParagraph => _currentParagraph;

  TtsService() {
    _tts.setCompletionHandler(() {
      final next = _currentParagraph + 1;
      if (next < _paragraphs.length) {
        _currentParagraph = next;
        onParagraphChanged?.call(next);
        _speakCurrent();
      } else {
        _isPlaying = false;
        onPlayingChanged?.call(false);
      }
    });

    _tts.setCancelHandler(() {
      _isPlaying = false;
      onPlayingChanged?.call(false);
    });

    _tts.setErrorHandler((msg) {
      _isPlaying = false;
      onPlayingChanged?.call(false);
    });
  }

  void setParagraphs(List<String> paragraphs, {int startAt = 0}) {
    stop();
    _paragraphs = paragraphs;
    _currentParagraph = startAt;
  }

  Future<void> play() async {
    if (_paragraphs.isEmpty) return;
    _isPlaying = true;
    onPlayingChanged?.call(true);
    await _speakCurrent();
  }

  Future<void> stop() async {
    await _tts.stop();
    _isPlaying = false;
    onPlayingChanged?.call(false);
  }

  Future<void> skipForward() async {
    await _tts.stop();
    if (_currentParagraph < _paragraphs.length - 1) {
      _currentParagraph++;
      onParagraphChanged?.call(_currentParagraph);
      if (_isPlaying) await _speakCurrent();
    }
  }

  Future<void> skipBackward() async {
    await _tts.stop();
    if (_currentParagraph > 0) {
      _currentParagraph--;
      onParagraphChanged?.call(_currentParagraph);
      if (_isPlaying) await _speakCurrent();
    }
  }

  // flutter_tts on Android: 0.0–1.0 range where 0.5 = normal.
  // User-facing speeds (0.75x, 1.0x, 1.25x, 1.5x) map to 0.375, 0.5, 0.625, 0.75.
  double _toNativeRate(double userSpeed) => userSpeed * 0.5;

  Future<void> setSpeed(double speed) async {
    _speed = speed;
    await _tts.setSpeechRate(_toNativeRate(speed));
    if (_isPlaying) {
      await _tts.stop();
      await _speakCurrent();
    }
  }

  Future<void> _speakCurrent() async {
    if (_currentParagraph >= _paragraphs.length) return;
    await _tts.setSpeechRate(_toNativeRate(_speed));
    await _tts.speak(_paragraphs[_currentParagraph]);
  }

  Future<void> dispose() async {
    await _tts.stop();
  }
}
