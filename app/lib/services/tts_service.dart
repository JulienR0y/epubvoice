import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  // User intent to play, distinct from the native cancel callback. Skip and
  // speed changes stop the engine internally; intent decides whether to resume.
  bool _intendedPlaying = false;
  // Set while a skip/speed change stops the engine, so the cancel handler does
  // not clobber intent for an internally triggered stop.
  bool _suppressCancel = false;
  double _speed = 1.0;
  int _currentParagraph = 0;
  List<String> _paragraphs = [];
  void Function(int index)? onParagraphChanged;
  void Function(bool playing)? onPlayingChanged;
  void Function()? onChapterComplete;

  bool get isPlaying => _intendedPlaying;
  double get speed => _speed;
  int get currentParagraph => _currentParagraph;

  TtsService() {
    _tts.setCompletionHandler(() {
      final next = _currentParagraph + 1;
      if (next < _paragraphs.length) {
        _currentParagraph = next;
        onParagraphChanged?.call(next);
        _speakCurrent();
      } else if (onChapterComplete != null) {
        onChapterComplete!();
      } else {
        _intendedPlaying = false;
        onPlayingChanged?.call(false);
      }
    });

    _tts.setCancelHandler(() {
      if (_suppressCancel) return;
      _intendedPlaying = false;
      onPlayingChanged?.call(false);
    });

    _tts.setErrorHandler((msg) {
      _intendedPlaying = false;
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
    _intendedPlaying = true;
    onPlayingChanged?.call(true);
    await _speakCurrent();
  }

  Future<void> stop() async {
    _intendedPlaying = false;
    await _tts.stop();
    onPlayingChanged?.call(false);
  }

  Future<void> skipForward() async {
    _suppressCancel = true;
    await _tts.stop();
    if (_currentParagraph < _paragraphs.length - 1) {
      _currentParagraph++;
      onParagraphChanged?.call(_currentParagraph);
      if (_intendedPlaying) await _speakCurrent();
    }
    _suppressCancel = false;
  }

  Future<void> skipBackward() async {
    _suppressCancel = true;
    await _tts.stop();
    if (_currentParagraph > 0) {
      _currentParagraph--;
      onParagraphChanged?.call(_currentParagraph);
      if (_intendedPlaying) await _speakCurrent();
    }
    _suppressCancel = false;
  }

  // flutter_tts on Android: 0.0–1.0 range where 0.5 = normal.
  // User-facing speeds (0.75x, 1.0x, 1.25x, 1.5x) map to 0.375, 0.5, 0.625, 0.75.
  double _toNativeRate(double userSpeed) => userSpeed * 0.5;

  Future<void> setSpeed(double speed) async {
    _speed = speed;
    await _tts.setSpeechRate(_toNativeRate(speed));
    if (_intendedPlaying) {
      _suppressCancel = true;
      await _tts.stop();
      await _speakCurrent();
      _suppressCancel = false;
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
