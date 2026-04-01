import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:path/path.dart' as p;
import 'package:epubvoice/models/chapter.dart';

class EpubParser {
  static Future<List<Chapter>> parse(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // 1. Find the rootfile from META-INF/container.xml
    final container = _findFile(archive, 'META-INF/container.xml');
    if (container == null) return [];
    final containerXml = XmlDocument.parse(String.fromCharCodes(container));
    final rootFilePath = containerXml
        .findAllElements('rootfile')
        .first
        .getAttribute('full-path')!;

    // 2. Parse the OPF (content.opf)
    final opfBytes = _findFile(archive, rootFilePath);
    if (opfBytes == null) return [];
    final opf = XmlDocument.parse(String.fromCharCodes(opfBytes));
    final opfDir = p.dirname(rootFilePath);

    // 3. Build id → href map from manifest
    final manifest = <String, String>{};
    for (final item in opf.findAllElements('item')) {
      final id = item.getAttribute('id');
      final href = item.getAttribute('href');
      if (id != null && href != null) {
        manifest[id] = href;
      }
    }

    // 4. Get reading order from spine
    final spineRefs = opf
        .findAllElements('itemref')
        .map((e) => e.getAttribute('idref'))
        .whereType<String>()
        .toList();

    // 5. Build TOC title map from toc.ncx if available
    final tocTitles = <String, String>{};
    final tocId = opf.findAllElements('spine').first.getAttribute('toc');
    if (tocId != null && manifest.containsKey(tocId)) {
      final tocPath = _resolvePath(opfDir, manifest[tocId]!);
      final tocBytes = _findFile(archive, tocPath);
      if (tocBytes != null) {
        final toc = XmlDocument.parse(String.fromCharCodes(tocBytes));
        for (final navPoint in toc.findAllElements('navPoint')) {
          final label = navPoint
              .findAllElements('navLabel')
              .firstOrNull
              ?.findAllElements('text')
              .firstOrNull
              ?.innerText
              .trim();
          final src = navPoint
              .findAllElements('content')
              .firstOrNull
              ?.getAttribute('src');
          if (label != null && src != null) {
            // Strip fragment (#anchor) for matching
            tocTitles[src.split('#').first] = label;
          }
        }
      }
    }

    // 6. Parse each spine item into a Chapter
    final chapters = <Chapter>[];
    for (final idref in spineRefs) {
      final href = manifest[idref];
      if (href == null) continue;

      final fullPath = _resolvePath(opfDir, href);
      final contentBytes = _findFile(archive, fullPath);
      if (contentBytes == null) continue;

      final html = String.fromCharCodes(contentBytes);
      final text = _stripHtml(html);
      final paragraphs = _splitIntoParagraphs(text);
      if (paragraphs.isEmpty) continue;

      final title = tocTitles[href] ??
          (paragraphs.first.length < 80 ? paragraphs.first : href);

      chapters.add(Chapter(title: title, paragraphs: paragraphs));
    }

    return chapters;
  }

  static Uint8List? _findFile(Archive archive, String path) {
    // Normalize path separators and try exact match
    final normalized = path.replaceAll('\\', '/');
    for (final file in archive.files) {
      if (file.name.replaceAll('\\', '/') == normalized) {
        return file.content as Uint8List;
      }
    }
    return null;
  }

  static String _resolvePath(String dir, String href) {
    if (dir.isEmpty) return href;
    return p.normalize('$dir/$href').replaceAll('\\', '/');
  }

  static String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</div>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  static List<String> _splitIntoParagraphs(String text) {
    return text
        .split(RegExp(r'\n+'))
        .map((p) => p.trim())
        .where((p) => p.length > 10)
        .toList();
  }
}
