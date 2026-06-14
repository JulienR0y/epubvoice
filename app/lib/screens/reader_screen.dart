import 'package:flutter/material.dart';
import 'package:epubvoice/models/chapter.dart';
import 'package:epubvoice/services/tts_service.dart';
import 'package:epubvoice/services/progress_service.dart';

class ReaderScreen extends StatefulWidget {
  final List<Chapter> chapters;
  final int initialChapter;

  const ReaderScreen({
    super.key,
    required this.chapters,
    required this.initialChapter,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final TtsService _tts;
  late int _chapterIndex;
  int _paragraphIndex = 0;
  bool _isPlaying = false;
  double _speed = 1.0;
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _paragraphKeys = [];

  static const _speeds = [0.75, 1.0, 1.25, 1.5];

  Chapter get _chapter => widget.chapters[_chapterIndex];

  @override
  void initState() {
    super.initState();
    _chapterIndex = widget.initialChapter;
    _tts = TtsService();
    _tts.onParagraphChanged = (index) {
      setState(() => _paragraphIndex = index);
      _scrollToParagraph(index);
      ProgressService.save(_chapterIndex, index);
    };
    _tts.onPlayingChanged = (playing) {
      setState(() => _isPlaying = playing);
    };
    _tts.onChapterComplete = _advanceChapter;
    _initParagraphKeys();
    _tts.setParagraphs(_chapter.paragraphs);
    _loadProgress();
  }

  void _advanceChapter() {
    final next = _chapterIndex + 1;
    if (next >= widget.chapters.length) {
      _tts.stop();
      return;
    }
    setState(() {
      _chapterIndex = next;
      _paragraphIndex = 0;
    });
    _initParagraphKeys();
    _tts.setParagraphs(_chapter.paragraphs);
    ProgressService.save(_chapterIndex, 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToParagraph(0);
    });
    _tts.play();
  }

  void _initParagraphKeys() {
    _paragraphKeys.clear();
    for (var i = 0; i < _chapter.paragraphs.length; i++) {
      _paragraphKeys.add(GlobalKey());
    }
  }

  Future<void> _loadProgress() async {
    final progress = await ProgressService.load();
    if (progress.chapter == _chapterIndex && progress.paragraph > 0) {
      setState(() => _paragraphIndex = progress.paragraph);
      _tts.setParagraphs(_chapter.paragraphs, startAt: progress.paragraph);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToParagraph(progress.paragraph);
      });
    }
  }

  void _scrollToParagraph(int index) {
    if (index < _paragraphKeys.length) {
      final key = _paragraphKeys[index];
      if (key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          alignment: 0.3,
          duration: const Duration(milliseconds: 300),
        );
      }
    }
  }

  void _cycleSpeed() {
    final currentIdx = _speeds.indexOf(_speed);
    final next = _speeds[(currentIdx + 1) % _speeds.length];
    setState(() => _speed = next);
    _tts.setSpeed(next);
  }

  @override
  void dispose() {
    _tts.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_chapter.title, maxLines: 1)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _chapter.paragraphs.length,
              itemBuilder: (context, index) {
                final isActive = index == _paragraphIndex;
                return Container(
                  key: _paragraphKeys[index],
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 4,
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: isActive
                      ? BoxDecoration(
                          color: const Color(0xFF2a2a2a),
                          borderRadius: BorderRadius.circular(4),
                        )
                      : null,
                  child: Text(
                    _chapter.paragraphs[index],
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.65,
                      color: isActive ? Colors.white : const Color(0xFFcccccc),
                    ),
                  ),
                );
              },
            ),
          ),
          // Player controls
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF111111),
              border: Border(
                top: BorderSide(color: Color(0xFF2a2a2a)),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous, size: 32),
                      color: Colors.white,
                      onPressed: () {
                        _tts.skipBackward();
                        setState(() =>
                            _paragraphIndex = _tts.currentParagraph);
                      },
                    ),
                    const SizedBox(width: 24),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 32,
                          color: const Color(0xFF1a1a1a),
                        ),
                        onPressed: () {
                          if (_isPlaying) {
                            _tts.stop();
                          } else {
                            _tts.play();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      icon: const Icon(Icons.skip_next, size: 32),
                      color: Colors.white,
                      onPressed: () {
                        _tts.skipForward();
                        setState(() =>
                            _paragraphIndex = _tts.currentParagraph);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _cycleSpeed,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF444444)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                  ),
                  child: Text(
                    '${_speed}x',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
