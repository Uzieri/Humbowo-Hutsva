// services/settings_service.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static SettingsService? _instance;
  static SettingsService get instance => _instance ??= SettingsService._();

  SettingsService._();

  SharedPreferences? _prefs;

  // Settings keys
  static const String _fontSizeKey = 'font_size';
  static const String _isDarkModeKey = 'is_dark_mode';
  static const String _textColorKey = 'text_color';
  static const String _backgroundColorKey = 'background_color';
  static const String _readingProgressKey = 'reading_progress';
  static const String _bookmarksKey = 'bookmarks';
  static const String _lastReadChapterKey = 'last_read_chapter';
  static const String _lastReadVerseKey = 'last_read_verse';
  static const String _languageKey = 'selected_language';

  // Initialize SharedPreferences
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Font Size Settings (12.0 - 24.0)
  double get fontSize => _prefs?.getDouble(_fontSizeKey) ?? 16.0;

  Future<void> setFontSize(double size) async {
    await _prefs?.setDouble(_fontSizeKey, size);
  }

  // Theme Settings
  bool get isDarkMode => _prefs?.getBool(_isDarkModeKey) ?? false;

  Future<void> setDarkMode(bool isDark) async {
    await _prefs?.setBool(_isDarkModeKey, isDark);
  }

  // Language Settings
  String get selectedLanguage => _prefs?.getString(_languageKey) ?? 'shona';

  Future<void> setLanguage(String language) async {
    await _prefs?.setString(_languageKey, language);
  }

  bool get isShona => selectedLanguage == 'shona';
  bool get isEnglish => selectedLanguage == 'english';

  // Text Color Settings
  Color get textColor {
    final colorValue = _prefs?.getInt(_textColorKey);
    if (colorValue != null) {
      return Color(colorValue);
    }
    return isDarkMode ? Colors.white : Colors.black87;
  }

  Future<void> setTextColor(Color color) async {
    await _prefs?.setInt(_textColorKey, color.value);
  }

  // Background Color Settings
  Color get backgroundColor {
    final colorValue = _prefs?.getInt(_backgroundColorKey);
    if (colorValue != null) {
      return Color(colorValue);
    }
    return isDarkMode ? Colors.grey[900]! : Colors.white;
  }

  Future<void> setBackgroundColor(Color color) async {
    await _prefs?.setInt(_backgroundColorKey, color.value);
  }

  // Reading Progress
  Map<int, int> get readingProgress {
    final progressJson = _prefs?.getStringList(_readingProgressKey) ?? [];
    Map<int, int> progress = {};

    for (String item in progressJson) {
      final parts = item.split(':');
      if (parts.length == 2) {
        final chapter = int.tryParse(parts[0]);
        final verse = int.tryParse(parts[1]);
        if (chapter != null && verse != null) {
          progress[chapter] = verse;
        }
      }
    }

    return progress;
  }

  Future<void> setReadingProgress(int chapter, int verse) async {
    final progress = readingProgress;
    progress[chapter] = verse;

    final progressList = progress.entries
        .map((entry) => '${entry.key}:${entry.value}')
        .toList();

    await _prefs?.setStringList(_readingProgressKey, progressList);

    // Also update last read position
    await setLastReadPosition(chapter, verse);
  }

  // Last Read Position
  int get lastReadChapter => _prefs?.getInt(_lastReadChapterKey) ?? 1;
  int get lastReadVerse => _prefs?.getInt(_lastReadVerseKey) ?? 1;

  Future<void> setLastReadPosition(int chapter, int verse) async {
    await _prefs?.setInt(_lastReadChapterKey, chapter);
    await _prefs?.setInt(_lastReadVerseKey, verse);
  }

  // Bookmarks
  Set<String> get bookmarks {
    final bookmarksList = _prefs?.getStringList(_bookmarksKey) ?? [];
    return bookmarksList.toSet();
  }

  Future<void> addBookmark(int chapter, int verse) async {
    final bookmarks = this.bookmarks;
    bookmarks.add('$chapter:$verse');
    await _prefs?.setStringList(_bookmarksKey, bookmarks.toList());
  }

  Future<void> removeBookmark(int chapter, int verse) async {
    final bookmarks = this.bookmarks;
    bookmarks.remove('$chapter:$verse');
    await _prefs?.setStringList(_bookmarksKey, bookmarks.toList());
  }

  bool isBookmarked(int chapter, int verse) {
    return bookmarks.contains('$chapter:$verse');
  }

  // Get bookmarked verses as a list
  List<Map<String, int>> getBookmarksList() {
    return bookmarks.map((bookmark) {
      final parts = bookmark.split(':');
      return {'chapter': int.parse(parts[0]), 'verse': int.parse(parts[1])};
    }).toList()..sort((a, b) {
      final chapterCompare = a['chapter']!.compareTo(b['chapter']!);
      if (chapterCompare != 0) return chapterCompare;
      return a['verse']!.compareTo(b['verse']!);
    });
  }

  // Reading Statistics
  double getReadingProgressPercentage() {
    final progress = readingProgress;
    if (progress.isEmpty) return 0.0;

    // Simplified calculation: number of chapters with progress / 26
    return (progress.length / 26.0) * 100;
  }

  // Reset all settings
  Future<void> resetAllSettings() async {
    await _prefs?.clear();
  }

  // Theme data
  ThemeData get themeData {
    return isDarkMode
        ? ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Colors.grey[900],
            cardColor: Colors.grey[800],
          )
        : ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Colors.grey[50],
            cardColor: Colors.white,
          );
  }
}
