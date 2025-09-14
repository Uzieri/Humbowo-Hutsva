import 'package:flutter/material.dart';
import '../config/app_routes.dart';
import '../models/book_models.dart';
import '../services/book_service.dart';
import '../services/settings_service.dart';
import '../widgets/language_selector.dart';

class ChaptersPage extends StatefulWidget {
  const ChaptersPage({super.key});

  @override
  State<ChaptersPage> createState() => _ChaptersPageState();
}

class _ChaptersPageState extends State<ChaptersPage> {
  List<Chapter> chapters = [];
  bool isLoading = true;
  String? errorMessage;
  String? currentLanguage;
  final SettingsService _settingsService = SettingsService.instance;

  // Add a flag to prevent multiple simultaneous reloads
  bool _isReloading = false;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    await _settingsService.init();
    if (mounted) {
      setState(() {
        currentLanguage = _settingsService.selectedLanguage;
      });
    }
    await _loadChapters();
  }

  // Improved language change detection with forced refresh
  Future<void> _checkLanguageChange() async {
    if (_isReloading) return; // Prevent multiple simultaneous reloads

    await _settingsService.init();
    final newLanguage = _settingsService.selectedLanguage;

    print(
      '🔍 DEBUG: _checkLanguageChange - Current: $currentLanguage, New: $newLanguage',
    );

    if (newLanguage != currentLanguage) {
      print('🔍 DEBUG: Language changed, forcing reload...');

      setState(() {
        currentLanguage = newLanguage;
        _isReloading = true;
      });

      // Force clear all caches and reload
      await BookService.instance
          .reloadBook(); // Use reloadBook instead of onLanguageChanged
      await _loadChapters();

      setState(() {
        _isReloading = false;
      });
    }
  }

  // Enhanced load chapters method with better error handling
  Future<void> _loadChapters() async {
    if (!mounted) return;

    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      print('🔍 DEBUG: _loadChapters called for language: $currentLanguage');

      // Get fresh chapters without relying on cache
      final book = await BookService.instance.getCurrentBook();
      final chapters = book.chapters;

      if (mounted) {
        setState(() {
          this.chapters = chapters;
          isLoading = false;
        });
        print('🔍 DEBUG: Chapters loaded: ${chapters.length} chapters');
      }
    } catch (e) {
      print('❌ ERROR loading chapters: $e');
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to load chapters: $e';
          isLoading = false;
        });
      }
    }
  }

  // Improved navigation back method
  void _navigateBack() {
    print('🔍 DEBUG: _navigateBack called');

    // Always try to pop first
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      // If we can't pop, navigate to cover but ensure it's available
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.cover,
        (route) => false, // Remove all previous routes
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = currentLanguage ?? 'shona';

    return WillPopScope(
      onWillPop: () async {
        _navigateBack();
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 219, 212, 212),
        appBar: AppBar(
          title: Text(
            language == 'english' ? 'New Apostolic Evidence' : 'Humbowo Hutsva',
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _navigateBack,
          ),
          actions: [
            // Enhanced language selector with better callback
            LanguageSelector(
              onLanguageChanged: () {
                print('🔍 DEBUG: Language selector callback triggered');
                // Add a small delay to ensure settings are saved
                Future.delayed(const Duration(milliseconds: 100), () {
                  _checkLanguageChange();
                });
              },
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.settings).then((_) {
                  // Check for language change when returning from settings
                  _checkLanguageChange();
                });
              },
            ),
          ],
        ),
        body: _buildBody(),
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
            Text(
              language == 'english'
                  ? 'Loading chapters...'
                  : 'Kuverenga zvitsauko...',
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Times New Roman',
              ),
            ),
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
              onPressed: _loadChapters,
              child: Text(language == 'english' ? 'Retry' : 'Edza'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: Colors.grey[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                language == 'english' ? 'Chapters' : 'Zvitsauko',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  fontFamily: 'Times New Roman',
                ),
              ),
              /*  const SizedBox(height: 8),
              Text(
                language == 'english'
                    ? '${chapters.length} chapters available'
                    : 'Zvitsauko ${chapters.length} zviripo',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),*/
            ],
          ),
        ),

        // Chapters list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadChapters,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chapters.length,
              itemBuilder: (context, index) {
                final chapter = chapters[index];
                return _buildChapterCard(context, chapter);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChapterCard(BuildContext context, Chapter chapter) {
    final language = currentLanguage ?? 'shona';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: const Color.fromARGB(
            255,
            196,
            221,
            221,
          ).withValues(alpha: 0.3),
          highlightColor: const Color.fromARGB(
            255,
            196,
            221,
            221,
          ).withValues(alpha: 0.1),
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.chapterDetail,
              arguments: chapter.number,
            ).then((_) {
              // Check for language change when returning from chapter detail
              _checkLanguageChange();
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue[600]!, Colors.blue[700]!],
              ),
            ),
            child: Row(
              children: [
                // Chapter number circle
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      '${chapter.number}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Times New Roman',
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Chapter info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter.displayTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Times New Roman',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        language == 'english'
                            ? '${chapter.verses.length} verse${chapter.verses.length == 1 ? '' : 's'}'
                            : 'Mavhesi ${chapter.verses.length}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          fontFamily: 'Times New Roman',
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
