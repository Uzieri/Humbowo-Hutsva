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
        backgroundColor: const Color.fromARGB(255, 201, 194, 194),
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
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: language == 'english'
                  ? 'Open Chapters'
                  : 'Vhura Zvitsauko',
            ),
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
                Navigator.pushNamed(context, AppRoutes.settings).then((
                  _,
                ) async {
                  // Reload settings when returning from settings page
                  await _settingsService.init();
                  final newLanguage = _settingsService.selectedLanguage;

                  if (mounted) {
                    setState(() {
                      currentLanguage = newLanguage;
                    });
                  }

                  // Also check for language change specifically
                  _checkLanguageChange();
                });
              },
            ),
          ],
        ),
        drawer: _buildChaptersDrawer(),
        floatingActionButton: FloatingActionButton.small(
          onPressed: _navigateBack,
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          tooltip: currentLanguage == 'english' ? 'Go Back' : 'Dzokera Shure',
          child: const Icon(Icons.arrow_back, size: 20),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: _buildMainContent(),
      ),
    );
  }

  // Build the chapters drawer with smaller sizing
  Widget _buildChaptersDrawer() {
    final language = currentLanguage ?? 'shona';

    return Drawer(
      backgroundColor: Color.fromARGB(255, 201, 194, 194),
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
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
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
                              errorMessage!,
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
                          final chapter = chapters[index];
                          return _buildDrawerChapterCard(context, chapter);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Build smaller chapter cards for drawer
  Widget _buildDrawerChapterCard(BuildContext context, Chapter chapter) {
    final language = currentLanguage ?? 'shona';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
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
            Navigator.pop(context); // Close drawer first
            Navigator.pushNamed(
              context,
              AppRoutes.chapterDetail,
              arguments: chapter.number,
            ).then((_) {
              _checkLanguageChange();
            });
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue[600]!, Colors.blue[700]!],
              ),
            ),
            child: Row(
              children: [
                // Smaller chapter number circle
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '${chapter.number}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Times New Roman',
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Chapter info - smaller
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter.displayTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Times New Roman',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        language == 'english'
                            ? '${chapter.verses.length} verse${chapter.verses.length == 1 ? '' : 's'}'
                            : 'Mavhesi ${chapter.verses.length}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10,
                          fontFamily: 'Times New Roman',
                        ),
                      ),
                    ],
                  ),
                ),

                // Smaller arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.8),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build main content with the permanent text - theme-aware
  Widget _buildMainContent() {
    final language = currentLanguage ?? 'shona';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instruction text - theme-aware
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _settingsService.isDarkMode
                  ? Colors.blue[900]!.withOpacity(0.3)
                  : Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _settingsService.isDarkMode
                    ? Colors.blue[400]!
                    : Colors.blue[200]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.menu,
                  color: _settingsService.isDarkMode
                      ? Colors.blue[300]
                      : Colors.blue[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    language == 'english'
                        ? 'Tap the menu icon above to view chapters'
                        : 'Dzvanya icon yemenu pamusoro kuti uone zvitsauko',
                    style: TextStyle(
                      color: _settingsService.isDarkMode
                          ? Colors.blue[200]
                          : const Color.fromARGB(255, 35, 21, 192),
                      fontSize:
                          _settingsService.fontSize *
                          0.75, // Smaller instruction text
                      fontFamily: 'Times New Roman',
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Main title - theme-aware
          Text(
            language == 'english'
                ? 'ABOUT APOSTLE JOHN MARANGE'
                : 'ZVEMUTUMWA JOHN MARANGE',
            style: TextStyle(
              fontSize: _settingsService.fontSize + 8, // Larger title
              fontWeight: FontWeight.bold,
              color: _settingsService.textColor,
              fontFamily: 'Times New Roman',
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Main content - theme-aware
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _settingsService.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: _settingsService.isDarkMode
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Text(
              language == 'english'
                  ? '''Mtema begot Momberume, Momberume begot John, who is called John Marange today.

In the year seventeen 1917 Jehovah began to visit him when he was five years old. In the sixth year he received the holy spirit. This is the Apostolic Church today from 1912 his birth to receiving the Spirit in 1917. The year 1917 I completed five years (5 yrs) sixth (6 yrs) that is when I began to receive the spirit of the Lord, the Holy Spirit.'''
                  : '''Mtema wakabereka Momberume, Momberume wakabereka John, ndiye unonzi John Marange nhasi.

Ngegore regumi nemanomwe 1917 Jehovha akavambe kumushanyira aine makore mashanu. Mune retanhatu akagashire mudzimu unoera. Iyi ndiyoyi Apostori Chechi nhasi kubvira gore ra1912 kuberekwa kwake kugashira Mweya 1917. Gore ra1917 ndapedza makore mashanu (5 yrs) retanhatu (6 yrs) ndiro randakavambe kugashira mudzimu waTenzi Mweya Mutsvene.''',
              style: TextStyle(
                fontSize: _settingsService.fontSize,
                height: 1.6,
                color: _settingsService.textColor,
                fontFamily: 'Times New Roman',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
