// services/verse_of_day_service.dart

import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/book_models.dart';
import '../services/settings_service.dart';
import '../services/book_service.dart';
import '../config/app_routes.dart';

class VerseOfDayService {
  static VerseOfDayService? _instance;
  static VerseOfDayService get instance => _instance ??= VerseOfDayService._();

  VerseOfDayService._();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final SettingsService _settingsService = SettingsService.instance;
  SharedPreferences? _prefs;

  // Storage keys
  static const String _lastVerseDate = 'verse_last_date';
  static const String _currentVerseChapter = 'verse_current_chapter';
  static const String _currentVerseNumber = 'verse_current_number';
  static const String _isVerseOfDayEnabled = 'verse_enabled';
  static const String _notificationTime = 'verse_notification_time';
  static const String _lastPopupShown = 'verse_last_popup';

  VerseOfDay? _currentVerseOfDay;

  // Getters
  VerseOfDay? get currentVerseOfDay => _currentVerseOfDay;

  bool get isEnabled {
    return _prefs?.getBool(_isVerseOfDayEnabled) ?? true;
  }

  TimeOfDay get notificationTime {
    final timeString = _prefs?.getString(_notificationTime) ?? '08:00';
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  // Initialize the service
  Future<void> initialize() async {
    try {
      await _settingsService.init();
      _prefs = await SharedPreferences.getInstance();
      await _initializeTimezone();

      // Request permissions BEFORE initializing notifications
      final hasPermission = await _requestNotificationPermissions();
      if (!hasPermission) {
        print('Notification permissions not granted');
      }

      await _initializeNotifications();
      await _loadCurrentVerseOfDay();

      if (isEnabled && hasPermission) {
        await _scheduleNotifications();
      }
    } catch (e) {
      print('Error initializing VerseOfDayService: $e');
    }
  }

  // Request notification permissions for Android 13+ and iOS
  Future<bool> _requestNotificationPermissions() async {
    try {
      // Check if we're on Android 13+
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;

        // Android 13+ requires explicit permission request
        if (androidInfo.version.sdkInt >= 33) {
          final status = await Permission.notification.request();
          print('Notification permission status: $status');

          if (!status.isGranted) {
            print('Notification permission denied');
            return false;
          }
        }

        // Android 12+ requires exact alarm permission
        if (androidInfo.version.sdkInt >= 31) {
          final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
          if (!exactAlarmStatus.isGranted) {
            final result = await Permission.scheduleExactAlarm.request();
            print('Exact alarm permission status: $result');
            if (!result.isGranted) {
              print(
                'Exact alarm permission denied - notifications may not work reliably',
              );
            }
          }
        }
      } else if (Platform.isIOS) {
        // iOS permission request
        final bool? granted = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        return granted ?? false;
      }

      return true;
    } catch (e) {
      print('Error requesting notification permissions: $e');
      return false;
    }
  }

  // Initialize timezone
  Future<void> _initializeTimezone() async {
    try {
      tz.initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      print('Timezone initialized: $timeZoneName');
    } catch (e) {
      print('Error initializing timezone: $e');
      // Fallback to UTC if timezone detection fails
      tz.setLocalLocation(tz.UTC);
    }
  }

  // Initialize local notifications
  Future<void> _initializeNotifications() async {
    try {
      // Android initialization with notification channel
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // iOS initialization
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        notificationCategories: [],
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final initialized = await _flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
        onDidReceiveBackgroundNotificationResponse:
            _onBackgroundNotificationTapped,
      );

      print('Notifications initialized: $initialized');

      // Create notification channel for Android 8.0+
      if (Platform.isAndroid) {
        await _createNotificationChannel();
      }
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  // Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    try {
      const androidChannel = AndroidNotificationChannel(
        'verse_of_day',
        'Daily Verse',
        description: 'Daily spiritual verse notifications',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);

      print('Notification channel created');
    } catch (e) {
      print('Error creating notification channel: $e');
    }
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Reschedule the next day's notification
    _scheduleNotifications();
  }

  // Handle background notification tap (for when app is terminated)
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    print('Background notification tapped: ${response.payload}');
  }

  // Load or generate today's verse
  Future<void> _loadCurrentVerseOfDay() async {
    if (_prefs == null) return;

    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final lastDate = _prefs!.getString(_lastVerseDate);

      if (lastDate != today || _currentVerseOfDay == null) {
        await _generateNewVerseOfDay();
      } else {
        final chapterNumber = _prefs!.getInt(_currentVerseChapter);
        final verseNumber = _prefs!.getInt(_currentVerseNumber);

        if (chapterNumber != null && verseNumber != null) {
          final chapter = await BookService.instance.getChapter(chapterNumber);
          if (chapter != null) {
            final verse = chapter.getVerse(verseNumber);
            if (verse != null) {
              _currentVerseOfDay = VerseOfDay(
                chapter: chapter,
                verse: verse,
                date: DateTime.now(),
              );
            }
          }
        }
      }
    } catch (e) {
      print('Error loading verse of day: $e');
      await _generateNewVerseOfDay();
    }
  }

  // Generate a new random verse for today
  Future<void> _generateNewVerseOfDay() async {
    try {
      final chapters = await BookService.instance.getAllChapters();
      if (chapters.isEmpty) return;

      final random = Random();
      final randomChapter = chapters[random.nextInt(chapters.length)];
      final randomVerse =
          randomChapter.verses[random.nextInt(randomChapter.verses.length)];

      _currentVerseOfDay = VerseOfDay(
        chapter: randomChapter,
        verse: randomVerse,
        date: DateTime.now(),
      );

      // Save to preferences
      if (_prefs != null) {
        final today = DateTime.now().toIso8601String().split('T')[0];
        await _prefs!.setString(_lastVerseDate, today);
        await _prefs!.setInt(_currentVerseChapter, randomChapter.number);
        await _prefs!.setInt(_currentVerseNumber, randomVerse.number);
      }
    } catch (e) {
      print('Error generating verse of day: $e');
    }
  }

  // Schedule daily notifications
  Future<void> _scheduleNotifications() async {
    if (!isEnabled || _prefs == null) return;

    try {
      // Check if we have permission first
      bool hasPermission = await _checkNotificationPermission();
      if (!hasPermission) {
        print('No notification permission - cannot schedule notifications');
        return;
      }

      // Cancel all existing notifications
      await _flutterLocalNotificationsPlugin.cancelAll();

      final time = notificationTime;
      final language = _settingsService.selectedLanguage;

      const androidDetails = AndroidNotificationDetails(
        'verse_of_day',
        'Daily Verse',
        channelDescription: 'Daily spiritual verse notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ticker: 'Daily Verse',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Calculate next notification time
      final now = tz.TZDateTime.now(tz.local);
      var scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      // If the scheduled time for today has passed, schedule for tomorrow
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      // Schedule the notification
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        100, // unique notification ID
        language == 'english' ? '🌅 Daily Verse' : '🌅 Vesi reZuva',
        language == 'english'
            ? 'Your spiritual inspiration awaits! Tap to read today\'s verse.'
            : 'Kufuridza kwako kwemweya kwakakumirira! Dzvanya kuti uverenga vesi razuva.',
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'verse_of_day',
        matchDateTimeComponents: DateTimeComponents.time, // Daily repeat
      );

      print('✅ Notification scheduled successfully for: $scheduledTime');

      // Verify the notification was scheduled
      final pendingNotifications = await _flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
      print('Pending notifications count: ${pendingNotifications.length}');
      for (var notification in pendingNotifications) {
        print(
          'Pending notification ID: ${notification.id}, Title: ${notification.title}',
        );
      }
    } catch (e) {
      print('❌ Error scheduling notifications: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  // Check notification permission status
  Future<bool> _checkNotificationPermission() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          final status = await Permission.notification.status;
          return status.isGranted;
        }
      }
      return true; // Permission not required for older Android versions
    } catch (e) {
      print('Error checking notification permission: $e');
      return false;
    }
  }

  // Show verse of day popup
  Future<void> showVerseOfDayPopup(BuildContext context) async {
    if (_currentVerseOfDay == null) {
      await _loadCurrentVerseOfDay();
      if (_currentVerseOfDay == null) return;
    }

    final language = _settingsService.selectedLanguage;
    final verse = _currentVerseOfDay!;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.wb_sunny, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  language == 'english' ? 'Verse of the Day' : 'Vesi reZuva',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '"${verse.verse.text}"',
                  style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '— ${verse.chapter.displayTitle}, ${language == 'english' ? 'Verse' : 'Vesi'} ${verse.verse.number}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(language == 'english' ? 'Later' : 'Gare Gare'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(
                  context,
                  AppRoutes.chapterDetail,
                  arguments: verse.chapter.number,
                );
              },
              child: Text(
                language == 'english' ? 'Read Now' : 'Verenga Izvozvi',
              ),
            ),
          ],
        );
      },
    );
  }

  // Update notification settings
  Future<void> updateSettings({bool? enabled, TimeOfDay? time}) async {
    if (_prefs == null) return;

    try {
      if (enabled != null) {
        await _prefs!.setBool(_isVerseOfDayEnabled, enabled);
      }

      if (time != null) {
        final timeString =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        await _prefs!.setString(_notificationTime, timeString);
      }

      // Reschedule notifications with new settings
      if (isEnabled) {
        await _scheduleNotifications();
      } else {
        await _flutterLocalNotificationsPlugin.cancelAll();
      }
    } catch (e) {
      print('Error updating settings: $e');
    }
  }

  // Check if should show popup
  Future<bool> shouldShowTodaysVerse() async {
    if (_prefs == null || !isEnabled) return false;

    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final lastShown = _prefs!.getString(_lastPopupShown);
      return lastShown != today;
    } catch (e) {
      print('Error checking popup status: $e');
      return false;
    }
  }

  // Mark popup as shown today
  Future<void> markPopupShown() async {
    if (_prefs == null) return;

    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      await _prefs!.setString(_lastPopupShown, today);
    } catch (e) {
      print('Error marking popup shown: $e');
    }
  }

  // Check and reschedule notifications if needed
  Future<void> checkAndRescheduleNotifications() async {
    if (!isEnabled || _prefs == null) return;

    try {
      final pendingNotifications = await _flutterLocalNotificationsPlugin
          .pendingNotificationRequests();

      print(
        'Checking notifications - found ${pendingNotifications.length} pending',
      );

      // If no notifications are pending, reschedule
      if (pendingNotifications.isEmpty) {
        print('No pending notifications found - rescheduling...');
        await _scheduleNotifications();
      }
    } catch (e) {
      print('Error checking notifications: $e');
    }
  }

  // Force refresh today's verse
  Future<void> refreshTodaysVerse() async {
    await _generateNewVerseOfDay();
  }

  // Helper to get a formatted string for sharing
  String getVerseText() {
    if (_currentVerseOfDay == null) return '';

    final language = _settingsService.selectedLanguage;
    final verse = _currentVerseOfDay!;

    return '"${verse.verse.text}"\n\n— ${verse.chapter.displayTitle}, ${language == 'english' ? 'Verse' : 'Vesi'} ${verse.verse.number}';
  }

  // Test notification (for debugging)
  Future<void> testNotification() async {
    try {
      final language = _settingsService.selectedLanguage;

      const androidDetails = AndroidNotificationDetails(
        'verse_of_day',
        'Daily Verse',
        channelDescription: 'Daily spiritual verse notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        999, // test notification ID
        language == 'english' ? '🌅 Test Daily Verse' : '🌅 Yedza Vesi reZuva',
        language == 'english'
            ? 'This is a test notification. Your daily verses are working!'
            : 'Iyi inyevedzero. Mavesi ako emazuva ari kushanda!',
        notificationDetails,
        payload: 'test_verse_of_day',
      );

      print('✅ Test notification sent successfully');
    } catch (e) {
      print('❌ Error sending test notification: $e');
    }
  }
}

// Data model for verse of the day
class VerseOfDay {
  final Chapter chapter;
  final Verse verse;
  final DateTime date;

  VerseOfDay({required this.chapter, required this.verse, required this.date});
}
