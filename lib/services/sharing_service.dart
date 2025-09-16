// services/sharing_service.dart

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/book_models.dart';
import 'settings_service.dart';

class SharingService {
  static SharingService? _instance;
  static SharingService get instance => _instance ??= SharingService._();

  SharingService._();

  final SettingsService _settingsService = SettingsService.instance;

  // Get app name and attribution
  String get _appName {
    final language = _settingsService.selectedLanguage;
    if (language == 'english') {
      return 'Sacred Visions of the Apostle';
    } else {
      return 'Humbowo Hutsva wewaPostori';
    }
  }

  String get _attribution {
    final language = _settingsService.selectedLanguage;
    if (language == 'english') {
      return 'JOHN MARANGE APOSTLE';
    } else {
      return 'JOHN MARANGE MUBHABHATIBZI';
    }
  }

  String get _sharedVia {
    final language = _settingsService.selectedLanguage;
    if (language == 'english') {
      return 'Shared via Humbowo Hutsva App';
    } else {
      return 'Chakagovaniswa ne Humbowo Hutsva App';
    }
  }

  // Share a single verse
  Future<void> shareVerse({
    required Chapter chapter,
    required Verse verse,
    String? customMessage,
  }) async {
    final language = _settingsService.selectedLanguage;

    String content = '';

    if (customMessage != null && customMessage.isNotEmpty) {
      content += '$customMessage\n\n';
    }

    // Verse content
    content += '"${verse.text}"\n\n';

    // Reference
    if (language == 'english') {
      content += '— ${chapter.displayTitle}, Verse ${verse.number}\n';
      content += '  $_appName\n';
      content += '  $_attribution\n\n';
    } else {
      content += '— ${chapter.displayTitle}, Vesi ${verse.number}\n';
      content += '  $_appName\n';
      content += '  $_attribution\n\n';
    }

    content += _sharedVia;

    await Share.share(
      content,
      subject: language == 'english'
          ? '${chapter.displayTitle}, Verse ${verse.number}'
          : '${chapter.displayTitle}, Vesi ${verse.number}',
    );
  }

  // Share multiple verses
  Future<void> shareVerses({
    required Chapter chapter,
    required List<Verse> verses,
    String? customMessage,
  }) async {
    final language = _settingsService.selectedLanguage;

    String content = '';

    if (customMessage != null && customMessage.isNotEmpty) {
      content += '$customMessage\n\n';
    }

    // Verses content
    for (int i = 0; i < verses.length; i++) {
      final verse = verses[i];
      content += '${verse.number}. ${verse.text}';
      if (i < verses.length - 1) content += '\n\n';
    }

    content += '\n\n';

    // Reference
    final verseNumbers = verses.map((v) => v.number.toString()).join(', ');
    if (language == 'english') {
      content += '— ${chapter.displayTitle}, Verses $verseNumbers\n';
      content += '  $_appName\n';
      content += '  $_attribution\n\n';
    } else {
      content += '— ${chapter.displayTitle}, Mavhesi $verseNumbers\n';
      content += '  $_appName\n';
      content += '  $_attribution\n\n';
    }

    content += _sharedVia;

    await Share.share(
      content,
      subject: language == 'english'
          ? '${chapter.displayTitle}, Verses $verseNumbers'
          : '${chapter.displayTitle}, Mavhesi $verseNumbers',
    );
  }

  // Share entire chapter
  Future<void> shareChapter({
    required Chapter chapter,
    String? customMessage,
  }) async {
    final language = _settingsService.selectedLanguage;

    String content = '';

    if (customMessage != null && customMessage.isNotEmpty) {
      content += '$customMessage\n\n';
    }

    // Chapter title
    content += '${chapter.displayTitle}\n';
    content += '$_appName\n\n';

    // All verses (limit to first 5 verses if chapter is very long)
    final versesToShare = chapter.verses.length > 5
        ? chapter.verses.take(5).toList()
        : chapter.verses;

    for (int i = 0; i < versesToShare.length; i++) {
      final verse = versesToShare[i];
      content += '${verse.number}. ${verse.text}';
      if (i < versesToShare.length - 1) content += '\n\n';
    }

    // Add indicator if there are more verses
    if (chapter.verses.length > 5) {
      if (language == 'english') {
        content += '\n\n[... and ${chapter.verses.length - 5} more verses]';
      } else {
        content +=
            '\n\n[... uye mavhesi ${chapter.verses.length - 5} akawedzera]';
      }
    }

    content += '\n\n';

    // Attribution
    content += '— $_attribution\n';
    content += _sharedVia;

    await Share.share(content, subject: '${chapter.displayTitle} - $_appName');
  }

  // Share verse with custom formatting for social media
  Future<void> shareVerseForSocialMedia({
    required Chapter chapter,
    required Verse verse,
  }) async {
    final language = _settingsService.selectedLanguage;

    String content = '';

    // Quote-style formatting for social media
    content += '💫 "${verse.text}"\n\n';

    // Hashtags and reference
    if (language == 'english') {
      content += '— ${chapter.displayTitle}, Verse ${verse.number}\n';
      content += '#SacredVisions #JohnMarange #Faith #Inspiration #Apostolic';
    } else {
      content += '— ${chapter.displayTitle}, Vesi ${verse.number}\n';
      content += '#HumbowoHutsva #JohnMarange #Kutenda #Apostolic';
    }

    await Share.share(content);
  }

  // Share reading progress
  Future<void> shareReadingProgress({
    required int chaptersRead,
    required int totalChapters,
    required double progressPercentage,
  }) async {
    final language = _settingsService.selectedLanguage;

    String content = '';

    if (language == 'english') {
      content += '📖 My reading progress in $_appName:\n\n';
      content += '✅ Completed: $chaptersRead/$totalChapters chapters\n';
      content += '📊 Progress: ${progressPercentage.toInt()}%\n\n';
      content += 'Join me in this spiritual journey!\n\n';
    } else {
      content += '📖 Mafambiro angu ekuverenga mu $_appName:\n\n';
      content += '✅ Ndapedza: $chaptersRead/$totalChapters zvitsauko\n';
      content += '📊 Mafambiro: ${progressPercentage.toInt()}%\n\n';
      content += 'Joyina neni parwendo urwu rweku namata!\n\n';
    }

    content += _sharedVia;

    await Share.share(content);
  }

  // Share app recommendation
  Future<void> shareAppRecommendation() async {
    final language = _settingsService.selectedLanguage;

    String content = '';

    if (language == 'english') {
      content += '🙏 I recommend this amazing app!\n\n';
      content += '$_appName\n';
      content += 'by $_attribution\n\n';
      content += '📱 Features:\n';
      content += '• Read all 26 chapters\n';
      content += '• English & Shona languages\n';
      content += '• Bookmark favorite verses\n';
      content += '• Track reading progress\n';
      content += '• Beautiful, easy-to-read interface\n\n';
      content += 'Download and join this spiritual journey!';
    } else {
      content += '🙏 Ndinokurudzira app iyi inoshamisa!\n\n';
      content += '$_appName\n';
      content += 'na $_attribution\n\n';
      content += '📱 Zvinobatsira:\n';
      content += '• Verenga zvitsauko zvese 26\n';
      content += '• Mitauro yeChirungu nechiShona\n';
      content += '• Chengetedza mavesi anoda\n';
      content += '• Ongorora mafambiro ekuverenga\n';
      content += '• Interface yakanaka, nyore kuverenga\n\n';
      content += 'Dhaunilodha uye ujoine parwendo urwu rwekumata!';
    }

    await Share.share(content);
  }

  // Simplified showShareOptions method - only native platform sharing
  Future<void> showShareOptions({
    required BuildContext context,
    required Chapter chapter,
    Verse? verse,
    List<Verse>? selectedVerses,
  }) async {
    final language = _settingsService.selectedLanguage;

    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                language == 'english'
                    ? 'Share Options'
                    : 'Sarudza nzira yekugova',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Share single verse
              if (verse != null) ...[
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.share, color: Colors.blue),
                  ),
                  title: Text(
                    language == 'english'
                        ? 'Share This Verse'
                        : 'Govana Vhesi Iri',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    language == 'english'
                        ? 'Gmail, Messages, etc.'
                        : 'Gmail, Messages, zvimwe.',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    shareVerse(chapter: chapter, verse: verse);
                  },
                ),
              ],

              // Share selected verses
              if (selectedVerses != null && selectedVerses.isNotEmpty) ...[
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.select_all, color: Colors.green),
                  ),
                  title: Text(
                    language == 'english'
                        ? 'Share Selected Verses'
                        : 'Govana Mavhesi Akasarudzwa',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    language == 'english'
                        ? 'Gmail, Messages, etc.'
                        : 'Gmail, Messages, zvimwe.',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    shareVerses(chapter: chapter, verses: selectedVerses);
                  },
                ),
              ],

              // Share entire chapter
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.book, color: Colors.orange),
                ),
                title: Text(
                  language == 'english'
                      ? 'Share Entire Chapter'
                      : 'Govana Chitsauko Chose',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  language == 'english'
                      ? 'Gmail, Messages, etc.'
                      : 'Gmail, Messages, zvimwe.',
                ),
                onTap: () {
                  Navigator.pop(context);
                  shareChapter(chapter: chapter);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper method for direct sharing without modal
  Future<void> shareDirectly({
    required Chapter chapter,
    Verse? verse,
    List<Verse>? selectedVerses,
  }) async {
    if (selectedVerses != null && selectedVerses.isNotEmpty) {
      await shareVerses(chapter: chapter, verses: selectedVerses);
    } else if (verse != null) {
      await shareVerse(chapter: chapter, verse: verse);
    } else {
      await shareChapter(chapter: chapter);
    }
  }
}
