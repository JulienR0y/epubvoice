import 'package:shared_preferences/shared_preferences.dart';

class ProgressService {
  static const _keyChapter = 'epubvoice_chapter';
  static const _keyParagraph = 'epubvoice_paragraph';

  static Future<void> save(int chapterIndex, int paragraphIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyChapter, chapterIndex);
    await prefs.setInt(_keyParagraph, paragraphIndex);
  }

  static Future<({int chapter, int paragraph})> load() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      chapter: prefs.getInt(_keyChapter) ?? 0,
      paragraph: prefs.getInt(_keyParagraph) ?? 0,
    );
  }
}
