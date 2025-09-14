// main.dart - Updated with Verse of Day initialization

import 'package:flutter/material.dart';
import 'package:humbowo_hutsva_wewapostori/config/app_routes.dart';
import 'package:humbowo_hutsva_wewapostori/pages/chapter_detail.dart';
import 'package:humbowo_hutsva_wewapostori/pages/chapters.dart';
import 'package:humbowo_hutsva_wewapostori/pages/cover_page.dart';
import 'package:humbowo_hutsva_wewapostori/pages/settings_page.dart';
import 'package:humbowo_hutsva_wewapostori/services/verse_of_day_service.dart';

// Add this global navigator key for notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Verse of Day service
  await VerseOfDayService.instance.initialize();

  // Check and reschedule notifications if needed
  await VerseOfDayService.instance.checkAndRescheduleNotifications();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // Add this for notification navigation
      initialRoute: AppRoutes.cover,
      routes: {
        AppRoutes.cover: (context) => const CoverPageWithVerseCheck(),
        AppRoutes.chapters: (context) => const ChaptersPage(),
        AppRoutes.chapterDetail: (context) => const ChapterDetailPage(),
        AppRoutes.settings: (context) => const SettingsPage(),
      },
    );
  }
}

// Wrapper for CoverPage that checks for verse of day popup
class CoverPageWithVerseCheck extends StatefulWidget {
  const CoverPageWithVerseCheck({super.key});

  @override
  State<CoverPageWithVerseCheck> createState() =>
      _CoverPageWithVerseCheckState();
}

class _CoverPageWithVerseCheckState extends State<CoverPageWithVerseCheck> {
  @override
  void initState() {
    super.initState();
    // Check for verse of day popup after the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVerseOfDay();
    });
  }

  Future<void> _checkVerseOfDay() async {
    // Wait a moment for the page to settle
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      final shouldShow = await VerseOfDayService.instance
          .shouldShowTodaysVerse();
      if (shouldShow) {
        await VerseOfDayService.instance.showVerseOfDayPopup(context);
        await VerseOfDayService.instance.markPopupShown();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const CoverPage();
  }
}
