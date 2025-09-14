// services/book_service.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/book_models.dart';
import 'settings_service.dart';

class BookService {
  static BookService? _instance;
  static BookService get instance => _instance ??= BookService._();

  BookService._();

  Book? _shonaBook;
  Book? _englishBook;
  bool _shonaLoaded = false;
  bool _englishLoaded = false;

  // Cache for chapters to avoid reloading
  List<Chapter>? _cachedChapters;
  String? _cachedLanguage;

  // Load book data based on selected language
  Future<Book> loadBook() async {
    final SettingsService settingsService = SettingsService.instance;
    await settingsService.init();

    final String language = settingsService.selectedLanguage;
    print('🔍 DEBUG: Loading book for language: $language');

    if (language == 'english') {
      return await loadEnglishBook();
    } else {
      return await loadShonaBook();
    }
  }

  // Load Shona book
  Future<Book> loadShonaBook() async {
    if (_shonaLoaded && _shonaBook != null) {
      print('🔍 DEBUG: Returning cached Shona book');
      return _shonaBook!;
    }

    try {
      print('🔍 DEBUG: Loading Shona book from file...');

      // Try new filename first, fallback to old filename
      String jsonString;
      try {
        jsonString = await rootBundle.loadString(
          'assets/data/book_data_shona.json',
        );
        print('🔍 DEBUG: Loaded from book_data_shona.json');
      } catch (e) {
        print('🔍 DEBUG: Shona file not found, trying original filename...');
        jsonString = await rootBundle.loadString('assets/data/book_data.json');
        print('🔍 DEBUG: Loaded from book_data.json');
      }

      final Map<String, dynamic> jsonData = json.decode(jsonString);
      _shonaBook = Book.fromJson(jsonData);
      _shonaLoaded = true;

      print(
        '🔍 DEBUG: Shona book loaded - Title: ${_shonaBook!.title}, Chapters: ${_shonaBook!.chapters.length}',
      );
      return _shonaBook!;
    } catch (e, stackTrace) {
      print('❌ ERROR loading Shona book: $e');
      print('❌ STACK: $stackTrace');
      throw Exception('Failed to load Shona book data: $e');
    }
  }

  // Load English book
  Future<Book> loadEnglishBook() async {
    if (_englishLoaded && _englishBook != null) {
      print('🔍 DEBUG: Returning cached English book');
      return _englishBook!;
    }

    try {
      print(
        '🔍 DEBUG: Loading English book from assets/data/book_data_english.json...',
      );

      final String jsonString = await rootBundle.loadString(
        'assets/data/book_data_english.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      _englishBook = Book.fromJson(jsonData);
      _englishLoaded = true;

      print(
        '🔍 DEBUG: English book loaded - Title: ${_englishBook!.title}, Chapters: ${_englishBook!.chapters.length}',
      );
      return _englishBook!;
    } catch (e) {
      print('❌ ERROR: English book not available: $e');
      print('🔍 DEBUG: Falling back to Shona book');

      // Fallback to Shona if English not available
      return await loadShonaBook();
    }
  }

  // Get current book based on language setting
  Future<Book> getCurrentBook() async {
    final SettingsService settingsService = SettingsService.instance;
    await settingsService.init();

    final String language = settingsService.selectedLanguage;
    print('🔍 DEBUG: getCurrentBook() for language: $language');

    if (language == 'english') {
      return await loadEnglishBook();
    } else {
      return await loadShonaBook();
    }
  }

  // Get specific chapter
  Future<Chapter?> getChapter(int chapterNumber) async {
    final SettingsService settingsService = SettingsService.instance;
    await settingsService.init();
    final String language = settingsService.selectedLanguage;

    print('🔍 DEBUG: getChapter($chapterNumber) for language: $language');

    // Load the appropriate book first
    Book book;
    if (language == 'english') {
      book = await loadEnglishBook();
      print('🔍 DEBUG: Using English book for chapter');
    } else {
      book = await loadShonaBook();
      print('🔍 DEBUG: Using Shona book for chapter');
    }

    final chapter = book.getChapter(chapterNumber);
    if (chapter != null) {
      print('🔍 DEBUG: Found chapter ${chapter.number}: ${chapter.title}');
    } else {
      print('❌ ERROR: Chapter $chapterNumber not found');
    }

    return chapter;
  }

  // Get specific verse from a chapter
  Future<Verse?> getVerse(int chapterNumber, int verseNumber) async {
    final chapter = await getChapter(chapterNumber);
    return chapter?.getVerse(verseNumber);
  }

  // Get all chapters from current language with improved caching
  Future<List<Chapter>> getAllChapters() async {
    final SettingsService settingsService = SettingsService.instance;
    await settingsService.init();
    final String currentLanguage = settingsService.selectedLanguage;

    print('🔍 DEBUG: getAllChapters() called for language: $currentLanguage');

    // Always check if we need to reload due to language change
    if (_cachedLanguage != currentLanguage || _cachedChapters == null) {
      print('🔍 DEBUG: Language changed or no cache, reloading chapters...');
      print(
        '🔍 DEBUG: Cached language: $_cachedLanguage, Current language: $currentLanguage',
      );

      _cachedLanguage = currentLanguage;

      final book = await getCurrentBook();
      _cachedChapters = book.chapters;

      print(
        '🔍 DEBUG: Cached ${_cachedChapters!.length} chapters from ${book.title}',
      );
    } else {
      print(
        '🔍 DEBUG: Returning cached chapters for language: $_cachedLanguage',
      );
    }

    return _cachedChapters!;
  }

  // Check if English version is available
  Future<bool> isEnglishAvailable() async {
    try {
      await rootBundle.loadString('assets/data/book_data_english.json');
      print('🔍 DEBUG: English book is available');
      return true;
    } catch (e) {
      print('🔍 DEBUG: English book is not available: $e');
      return false;
    }
  }

  // Clear all cached data - improved implementation
  Future<void> clearCache() async {
    print('🔍 DEBUG: clearCache() called - clearing chapter cache only');
    _cachedChapters = null;
    _cachedLanguage = null;
    // Don't clear the loaded books to avoid reloading from assets
  }

  // Reset/reload book data - complete cache clear
  Future<void> reloadBook() async {
    print('🔍 DEBUG: reloadBook() called - clearing ALL cached data');

    // Clear everything including loaded books
    _shonaBook = null;
    _englishBook = null;
    _shonaLoaded = false;
    _englishLoaded = false;
    _cachedChapters = null;
    _cachedLanguage = null;

    // Force reload the current book
    await loadBook();
  }

  // Force reload when language changes - improved implementation
  Future<void> onLanguageChanged() async {
    print('🔍 DEBUG: onLanguageChanged() called');

    final SettingsService settingsService = SettingsService.instance;
    await settingsService.init();
    final String newLanguage = settingsService.selectedLanguage;

    print(
      '🔍 DEBUG: onLanguageChanged() - Current cached: $_cachedLanguage, New: $newLanguage',
    );

    // Always clear chapter cache when language changes
    _cachedChapters = null;
    _cachedLanguage = null;

    // Pre-load the new language book to ensure it's ready
    await loadBook();
  }

  // Get current cached language for debugging
  String? get currentCachedLanguage => _cachedLanguage;

  // Force clear all caches (useful for debugging)
  void forceReset() {
    print('🔍 DEBUG: forceReset() called - clearing EVERYTHING');
    _shonaBook = null;
    _englishBook = null;
    _shonaLoaded = false;
    _englishLoaded = false;
    _cachedChapters = null;
    _cachedLanguage = null;
  }
}
