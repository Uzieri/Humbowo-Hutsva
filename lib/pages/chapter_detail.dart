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

  // Drawer related variables
  List<Chapter> chapters = [];
  bool isLoadingChapters = true;
  String? chaptersErrorMessage;
  String? currentLanguage;

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
    _loadChapters(); // Load chapters for the drawer
  }

  Future<void> _loadSettings() async {
    await _settingsService.init();
    setState(() {
      _fontSize = _settingsService.fontSize;
      _isDarkMode = _settingsService.isDarkMode;
      _textColor = _settingsService.textColor;
      _backgroundColor = _settingsService.backgroundColor;
      currentLanguage = _settingsService.selectedLanguage;
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

  // Load chapters for the drawer
  Future<void> _loadChapters() async {
    try {
      setState(() {
        isLoadingChapters = true;
        chaptersErrorMessage = null;
      });

      await BookService.instance.loadBook();
      final allChapters = await BookService.instance.getAllChapters();

      setState(() {
        chapters = allChapters;
        isLoadingChapters = false;
      });
    } catch (e) {
      setState(() {
        chaptersErrorMessage = 'Failed to load chapters: $e';
        isLoadingChapters = false;
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
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
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
      drawer: _buildChaptersDrawer(),
      body: _buildBody(),
    );
  }

  Widget _buildChaptersDrawer() {
    final language = currentLanguage ?? 'shona';

    return Drawer(
      backgroundColor: const Color.fromARGB(255, 201, 194, 194),
      child: SafeArea(
        child: Column(
          children: [
            // Drawer header - reduced height
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue[600]!, Colors.blue[700]!],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      language == 'english' ? 'Chapters' : 'Zvitsauko',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Times New Roman',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      language == 'english'
                          ? '${chapters.length} chapters'
                          : 'Zvitsauko ${chapters.length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'Times New Roman',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Chapters list - properly constrained
            Expanded(
              child: isLoadingChapters
                  ? const Center(child: CircularProgressIndicator())
                  : chaptersErrorMessage != null
                  ? SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              chaptersErrorMessage!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadChapters,
                              child: Text(
                                language == 'english' ? 'Retry' : 'Edza',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadChapters,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        itemCount: chapters.length,
                        itemBuilder: (context, index) {
                          final chapterItem = chapters[index];
                          return _buildDrawerChapterCard(context, chapterItem);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerChapterCard(BuildContext context, Chapter chapterItem) {
    final isCurrentChapter = chapterItem.number == currentChapterNumber;
    final language = currentLanguage ?? 'shona';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      elevation: isCurrentChapter ? 4 : 1,
      color: isCurrentChapter ? Colors.blue[100] : Colors.white,
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isCurrentChapter ? Colors.blue[700] : Colors.grey[400],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${chapterItem.number}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isCurrentChapter ? 14 : 12,
              ),
            ),
          ),
        ),
        title: Text(
          chapterItem.displayTitle,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isCurrentChapter ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'Times New Roman',
            color: isCurrentChapter ? Colors.blue[900] : Colors.black87,
          ),
        ),
        subtitle: Text(
          language == 'english'
              ? '${chapterItem.verses.length} verses'
              : 'Mavesi ${chapterItem.verses.length}',
          style: TextStyle(
            fontSize: 10,
            color: isCurrentChapter ? Colors.blue[700] : Colors.grey[600],
          ),
        ),
        trailing: isCurrentChapter
            ? Icon(Icons.chevron_right, color: Colors.blue[700], size: 20)
            : null,
        selected: isCurrentChapter,
        selectedTileColor: Colors.blue[50],
        onTap: () {
          Navigator.pop(context); // Close drawer
          if (!isCurrentChapter) {
            _navigateToChapter(chapterItem.number);
          }
        },
      ),
    );
  }

  Widget _buildBody() {
    final language = currentLanguage ?? 'shona';
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
                language == 'english'
                    ? 'The New Testament of The Apostles'
                    : 'Humbowo Hutsva wewaPostori',
                style: TextStyle(
                  fontSize: 14,
                  color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                  fontFamily: 'Times New Roman',
                ),
              ),
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
                    style: const TextStyle(fontFamily: 'Times New Roman'),
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
                  icon: const Icon(
                    Icons.home,
                  ), // Changed from Icons.list to Icons.home
                  label: const Text(
                    'Home',
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
                  onPressed: currentChapterNumber < 25
                      ? () {
                          _navigateToChapter(currentChapterNumber + 1);
                        }
                      : null,
                  icon: const Icon(Icons.navigate_next),
                  label: Text(
                    'Chapter ${currentChapterNumber + 1}',
                    style: const TextStyle(fontFamily: 'Times New Roman'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentChapterNumber < 25
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
                  fontFamily: 'serif',
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
