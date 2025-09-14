// models/book_models.dart

class Book {
  final String title;
  final String subtitle;
  final List<String> authorLines;
  final String coverImage;
  final List<Chapter> chapters;

  Book({
    required this.title,
    required this.subtitle,
    required this.authorLines,
    required this.coverImage,
    required this.chapters,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      authorLines: List<String>.from(json['author_lines'] ?? []),
      coverImage: json['cover_image'] ?? '',
      chapters: (json['chapters'] as List<dynamic>? ?? [])
          .map((chapterJson) => Chapter.fromJson(chapterJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'author_lines': authorLines,
      'cover_image': coverImage,
      'chapters': chapters.map((chapter) => chapter.toJson()).toList(),
    };
  }

  // Helper methods
  Chapter? getChapter(int chapterNumber) {
    if (chapterNumber < 1 || chapterNumber > chapters.length) {
      return null;
    }
    return chapters[chapterNumber - 1];
  }

  int get totalChapters => chapters.length;
}

class Chapter {
  final int number;
  final String? title; // Optional chapter title
  final List<Verse> verses;

  Chapter({required this.number, this.title, required this.verses});

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      number: json['number'] ?? 0,
      title: json['title'],
      verses: (json['verses'] as List<dynamic>? ?? [])
          .map((verseJson) => Verse.fromJson(verseJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'title': title,
      'verses': verses.map((verse) => verse.toJson()).toList(),
    };
  }

  // Helper methods
  Verse? getVerse(int verseNumber) {
    if (verseNumber < 1 || verseNumber > verses.length) {
      return null;
    }
    return verses[verseNumber - 1];
  }

  int get totalVerses => verses.length;

  String get displayTitle => title ?? 'Chapter $number';
}

class Verse {
  final int number;
  final String text;

  Verse({required this.number, required this.text});

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(number: json['number'] ?? 0, text: json['text'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'number': number, 'text': text};
  }

  @override
  String toString() {
    return '$number. $text';
  }
}
