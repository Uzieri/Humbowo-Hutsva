import 'package:flutter/material.dart';
import 'package:humbowo_hutsva_wewapostori/services/sharing_service.dart';
import '../models/book_models.dart';
import '../services/book_service.dart';
import '../services/settings_service.dart';
import '../config/app_routes.dart';

class ChapterDetailPage extends StatefulWidget {
  const ChapterDetailPage({super.key});

  @override
  State<ChapterDetailPage> createState() => _ChapterDetailPageState();
}

class _ChapterDetailPageState extends State<ChapterDetailPage> {
  Chapter? chapter;
  bool isLoading = true;
  String? errorMessage;
  int currentChapterNumber = 1;

  final SettingsService _settingsService = SettingsService.instance;
  double _fontSize = 16.0;
  bool _isDarkMode = false;
  Color _textColor = Colors.black87;
  Color _backgroundColor = Colors.white;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSettings();
    _loadChapterData();
  }

  Future<void> _loadSettings() async {
    await _settingsService.init();
    setState(() {
      _fontSize = _settingsService.fontSize;
      _isDarkMode = _settingsService.isDarkMode;
      _textColor = _settingsService.textColor;
      _backgroundColor = _settingsService.backgroundColor;
    });
  }

  Future<void> _loadChapterData() async {
    final int chapterNumber =
        ModalRoute.of(context)?.settings.arguments as int? ?? 1;

    currentChapterNumber = chapterNumber;

    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Load the book first, then get the specific chapter
      await BookService.instance.loadBook();
      final chapterData = await BookService.instance.getChapter(chapterNumber);

      if (chapterData != null) {
        setState(() {
          chapter = chapterData;
          isLoading = false;
        });

        // Update reading progress
        await _settingsService.setReadingProgress(chapterNumber, 1);
      } else {
        setState(() {
          errorMessage = 'Chapter $chapterNumber not found';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load chapter: $e';
        isLoading = false;
      });
    }
  }

  void _navigateToChapter(int chapterNumber) {
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.chapterDetail,
      arguments: chapterNumber,
    );
  }

  Future<void> _toggleBookmark(int verseNumber) async {
    final isBookmarked = _settingsService.isBookmarked(
      currentChapterNumber,
      verseNumber,
    );

    if (isBookmarked) {
      await _settingsService.removeBookmark(currentChapterNumber, verseNumber);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bookmark removed')));
    } else {
      await _settingsService.addBookmark(currentChapterNumber, verseNumber);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bookmark added')));
    }

    setState(() {}); // Refresh to update bookmark icons
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          'Chapter $currentChapterNumber',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'Times New Roman',
          ),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.settings);
              // Reload settings when returning from settings page
              await _loadSettings();
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              if (chapter != null) {
                SharingService.instance.showShareOptions(
                  context: context,
                  chapter: chapter!,
                );
              }
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Loading chapter...', style: TextStyle(color: _textColor)),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: TextStyle(fontSize: 18, color: Colors.red[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadChapterData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (chapter == null) {
      return Center(
        child: Text('Chapter not found', style: TextStyle(color: _textColor)),
      );
    }

    return Column(
      children: [
        // Chapter header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.grey[800] : Colors.blue[50],
            border: Border(
              bottom: BorderSide(
                color: _isDarkMode ? Colors.grey[600]! : Colors.blue[200]!,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chapter!.displayTitle,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : Colors.blue[800],
                  fontFamily: 'Times New Roman',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Humbowo Hutsva wewaPostori',
                style: TextStyle(
                  fontSize: 14,
                  color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                  fontFamily: 'Times New Roman',
                ),
              ),
              const SizedBox(height: 4),
              /*  Text(
                '${chapter!.verses.length} verses',
                style: TextStyle(
                  fontSize: 12,
                  color: _isDarkMode ? Colors.white60 : Colors.grey[500],
                ),
              ),*/
            ],
          ),
        ),

        // Verses content
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chapter!.verses.length,
            itemBuilder: (context, index) {
              final verse = chapter!.verses[index];
              return _buildVerseCard(verse);
            },
          ),
        ),

        // Navigation buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.grey[800] : Colors.white,
            border: Border(
              top: BorderSide(
                color: _isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
              ),
            ),
          ),
          child: Row(
            children: [
              // Previous chapter button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: currentChapterNumber > 1
                      ? () {
                          _navigateToChapter(currentChapterNumber - 1);
                        }
                      : null,
                  icon: const Icon(Icons.navigate_before),
                  label: Text(
                    'Chapter ${currentChapterNumber - 1}',

                    style: TextStyle(fontFamily: 'Times New Roman'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentChapterNumber > 1
                        ? Colors.grey[600]
                        : Colors.grey[300],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Back to chapters button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.list),
                  label: const Text(
                    'Chapters',
                    style: TextStyle(fontFamily: 'Times New Roman'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Next chapter button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: currentChapterNumber < 26
                      ? () {
                          _navigateToChapter(currentChapterNumber + 1);
                        }
                      : null,
                  icon: const Icon(Icons.navigate_next),
                  label: Text(
                    'Chapter ${currentChapterNumber + 1}',
                    style: TextStyle(fontFamily: 'Times New Roman'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentChapterNumber < 26
                        ? Colors.blue[700]
                        : Colors.grey[300],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerseCard(Verse verse) {
    final isBookmarked = _settingsService.isBookmarked(
      currentChapterNumber,
      verse.number,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDarkMode ? Colors.grey[600]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: (_isDarkMode ? Colors.black : Colors.grey).withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verse number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.blue[800] : Colors.blue[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '${verse.number}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : Colors.blue[800],
                  fontSize: 14,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Verse text
          Expanded(
            child: GestureDetector(
              onLongPress: () async {
                await _settingsService.setReadingProgress(
                  currentChapterNumber,
                  verse.number,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Progress saved: Chapter $currentChapterNumber, Verse ${verse.number}',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Text(
                verse.text,
                style: TextStyle(
                  fontSize: _fontSize,
                  height: 1.5,
                  color: _textColor,
                  fontFamily:
                      'serif', // Use serif instead of Times New Roman for better compatibility
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Bookmark button
          GestureDetector(
            onTap: () => _toggleBookmark(verse.number),
            child: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? Colors.blue[700] : Colors.grey[400],
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
