import 'package:flutter/material.dart';
import '../services/book_service.dart';

class DebugNumberingTest extends StatefulWidget {
  const DebugNumberingTest({super.key});

  @override
  State<DebugNumberingTest> createState() => _DebugNumberingTestState();
}

class _DebugNumberingTestState extends State<DebugNumberingTest> {
  String debugInfo = "Loading...";

  @override
  void initState() {
    super.initState();
    _checkNumbering();
  }

  Future<void> _checkNumbering() async {
    try {
      final book = await BookService.instance.loadBook();
      final chapters = book.chapters;

      String info = "CHAPTER NUMBERING DEBUG:\n\n";
      info += "Total chapters: ${chapters.length}\n\n";

      info += "First 10 chapters:\n";
      for (int i = 0; i < chapters.length && i < 10; i++) {
        final chapter = chapters[i];
        info +=
            "Array index [$i] → Chapter number: ${chapter.number}, Title: ${chapter.title}\n";
      }

      info += "\nLast 3 chapters:\n";
      for (int i = chapters.length - 3; i < chapters.length; i++) {
        final chapter = chapters[i];
        info +=
            "Array index [$i] → Chapter number: ${chapter.number}, Title: ${chapter.title}\n";
      }

      info += "\nTesting getChapter method:\n";
      final chapter1 = book.getChapter(1);
      final chapter26 = book.getChapter(26);

      info += "getChapter(1) → ${chapter1?.number} (${chapter1?.title})\n";
      info += "getChapter(26) → ${chapter26?.number} (${chapter26?.title})\n";

      setState(() {
        debugInfo = info;
      });
    } catch (e) {
      setState(() {
        debugInfo = "ERROR: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Numbering'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              debugInfo,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }
}
