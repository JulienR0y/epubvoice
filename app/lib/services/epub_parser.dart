import 'dart:convert';
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
    final containerXml = XmlDocument.parse(utf8.decode(container));
    final rootFilePath = containerXml
        .findAllElements('rootfile')
        .first
        .getAttribute('full-path')!;

    // 2. Parse the OPF (content.opf)
    final opfBytes = _findFile(archive, rootFilePath);
    if (opfBytes == null) return [];
    final opf = XmlDocument.parse(utf8.decode(opfBytes));
    final opfDir = p.dirname(rootFilePath);

    // 3. Build id → href and id → media-type maps from manifest
    final manifest = <String, String>{};
    final mediaTypes = <String, String>{};
    for (final item in opf.findAllElements('item')) {
      final id = item.getAttribute('id');
      final href = item.getAttribute('href');
      final mediaType = item.getAttribute('media-type');
      if (id != null && href != null) {
        manifest[id] = href;
        if (mediaType != null) mediaTypes[id] = mediaType;
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
        final toc = XmlDocument.parse(utf8.decode(tocBytes));
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
          if (label != null && label.isNotEmpty && src != null) {
            tocTitles[src.split('#').first] = label;
          }
        }
      }
    }

    // Also try nav.xhtml (EPUB 3) for TOC
    if (tocTitles.isEmpty) {
      _parseEpub3Nav(opf, opfDir, archive, tocTitles);
    }

    // 6. Parse each spine item into a Chapter
    final chapters = <Chapter>[];
    for (final idref in spineRefs) {
      final href = manifest[idref];
      if (href == null) continue;

      // Skip non-XHTML content (images, CSS, etc.)
      final mediaType = mediaTypes[idref] ?? '';
      if (!mediaType.contains('html') && !mediaType.contains('xml')) continue;

      final fullPath = _resolvePath(opfDir, href);
      final contentBytes = _findFile(archive, fullPath);
      if (contentBytes == null) continue;

      final html = utf8.decode(contentBytes, allowMalformed: true);
      final text = _stripHtml(html);
      final paragraphs = _splitIntoParagraphs(text);
      if (paragraphs.isEmpty) continue;

      // Use TOC label, falling back to first short paragraph, then filename
      final title = tocTitles[href] ??
          tocTitles[Uri.decodeComponent(href)] ??
          (paragraphs.first.length < 80
              ? paragraphs.first
              : p.basenameWithoutExtension(href));

      chapters.add(Chapter(title: title, paragraphs: paragraphs));
    }

    return chapters;
  }

  static void _parseEpub3Nav(
    XmlDocument opf,
    String opfDir,
    Archive archive,
    Map<String, String> tocTitles,
  ) {
    // Find the nav document (properties="nav")
    for (final item in opf.findAllElements('item')) {
      final props = item.getAttribute('properties') ?? '';
      if (!props.contains('nav')) continue;

      final href = item.getAttribute('href');
      if (href == null) continue;

      final navPath = _resolvePath(opfDir, href);
      final navBytes = _findFile(archive, navPath);
      if (navBytes == null) continue;

      final nav = XmlDocument.parse(utf8.decode(navBytes, allowMalformed: true));
      for (final a in nav.findAllElements('a')) {
        final navHref = a.getAttribute('href')?.split('#').first;
        final label = a.innerText.trim();
        if (navHref != null && label.isNotEmpty) {
          tocTitles[navHref] = label;
        }
      }
      break;
    }
  }

  static Uint8List? _findFile(Archive archive, String path) {
    final normalized = path.replaceAll('\\', '/');
    for (final file in archive.files) {
      final name = file.name.replaceAll('\\', '/');
      if (name == normalized || name == '/$normalized') {
        return file.content as Uint8List;
      }
    }
    // Case-insensitive fallback
    final lower = normalized.toLowerCase();
    for (final file in archive.files) {
      if (file.name.replaceAll('\\', '/').toLowerCase() == lower) {
        return file.content as Uint8List;
      }
    }
    return null;
  }

  static String _resolvePath(String dir, String href) {
    if (dir.isEmpty || dir == '.') return href;
    return p.normalize('$dir/$href').replaceAll('\\', '/');
  }

  static String _stripHtml(String html) {
    // Remove <head>, <style>, <script> blocks entirely
    var text = html
        .replaceAll(RegExp(r'<head[^>]*>.*?</head>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true), '');

    // Block-level elements get line breaks
    text = text
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</(?:p|div|h[1-6]|li|tr|blockquote|section|article)>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<(?:p|div|h[1-6]|li|tr|blockquote|section|article)[^>]*>', caseSensitive: false), '\n');

    // Strip remaining tags
    text = text.replaceAll(RegExp(r'<[^>]+>'), '');

    // Decode HTML entities
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&mdash;', '\u2014')
        .replaceAll('&ndash;', '\u2013')
        .replaceAll('&hellip;', '\u2026')
        .replaceAll('&lsquo;', '\u2018')
        .replaceAll('&rsquo;', '\u2019')
        .replaceAll('&ldquo;', '\u201C')
        .replaceAll('&rdquo;', '\u201D')
        .replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
          final code = int.tryParse(m.group(1)!);
          return code != null ? String.fromCharCode(code) : '';
        })
        .replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) {
          final code = int.tryParse(m.group(1)!, radix: 16);
          return code != null ? String.fromCharCode(code) : '';
        });

    return text.trim();
  }

  static List<String> _splitIntoParagraphs(String text) {
    return text
        .split(RegExp(r'\n+'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
  }
}
