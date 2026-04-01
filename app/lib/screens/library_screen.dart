import 'package:flutter/material.dart';
import 'package:epubvoice/models/chapter.dart';
import 'package:epubvoice/screens/reader_screen.dart';

class LibraryScreen extends StatelessWidget {
  final List<Chapter> chapters;

  const LibraryScreen({super.key, required this.chapters});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chapters')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: chapters.length,
        separatorBuilder: (_, _) => const Divider(
          color: Color(0xFF2a2a2a),
          height: 1,
        ),
        itemBuilder: (context, index) {
          return ListTile(
            leading: Text(
              '${index + 1}',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            title: Text(
              chapters[index].title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReaderScreen(
                    chapters: chapters,
                    initialChapter: index,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
