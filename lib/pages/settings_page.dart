// pages/settings_page.dart - Updated with Test Notification Button

import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/verse_of_day_service.dart';
import '../config/app_routes.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsService _settingsService = SettingsService.instance;

  double _fontSize = 16.0;
  bool _isDarkMode = false;
  Color _selectedTextColor = Colors.black87;
  Color _selectedBackgroundColor = Colors.white;

  // Verse of Day settings
  bool _verseOfDayEnabled = true;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _settingsService.init();
    setState(() {
      _fontSize = _settingsService.fontSize;
      _isDarkMode = _settingsService.isDarkMode;
      _selectedTextColor = _settingsService.textColor;
      _selectedBackgroundColor = _settingsService.backgroundColor;

      // Load verse of day settings
      _verseOfDayEnabled = VerseOfDayService.instance.isEnabled;
      _notificationTime = VerseOfDayService.instance.notificationTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetSettings,
            tooltip: 'Reset to default',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Verse of the Day Section
          _buildSection(
            _settingsService.selectedLanguage == 'english'
                ? 'Daily Verse'
                : 'Vhesi reZuva',
            [
              _buildVerseOfDayToggle(),
              if (_verseOfDayEnabled) ...[
                _buildNotificationTimeCard(),
                _buildVerseOfDayActions(),
              ],
            ],
          ),

          const SizedBox(height: 20),

          _buildSection('Reading Preferences', [
            _buildFontSizeSlider(),
            _buildThemeToggle(),
          ]),

          const SizedBox(height: 20),

          _buildSection('Color Settings', [
            _buildTextColorPicker(),
            _buildBackgroundColorPicker(),
          ]),

          const SizedBox(height: 20),

          _buildSection('Reading Progress', [
            _buildProgressCard(),
            _buildContinueReadingButton(),
          ]),

          const SizedBox(height: 20),

          _buildSection('Bookmarks', [_buildBookmarksCard()]),

          const SizedBox(height: 20),

          _buildSection('Preview', [_buildPreviewCard()]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  // Verse of Day Settings Widgets
  Widget _buildVerseOfDayToggle() {
    final language = _settingsService.selectedLanguage;

    return Card(
      color: _isDarkMode ? Colors.grey[800] : Colors.white,
      child: SwitchListTile(
        title: Text(
          language == 'english'
              ? 'Daily Verse Notifications'
              : 'Zviziviso zveVhesi reZuva',
          style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
        ),
        subtitle: Text(
          language == 'english'
              ? 'Receive a random verse every morning'
              : 'Gamuchira vhesi rakasarudzwa mangwanani ose',
          style: TextStyle(
            color: _isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        value: _verseOfDayEnabled,
        activeThumbColor: Colors.orange[700],
        onChanged: (bool value) async {
          setState(() => _verseOfDayEnabled = value);
          await VerseOfDayService.instance.updateSettings(enabled: value);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  value
                      ? (language == 'english'
                            ? 'Daily verse enabled'
                            : 'Vhesi reZuva rakabatsiwa')
                      : (language == 'english'
                            ? 'Daily verse disabled'
                            : 'Vhesi reZuva rakamiswa'),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildNotificationTimeCard() {
    final language = _settingsService.selectedLanguage;

    return Card(
      color: _isDarkMode ? Colors.grey[800] : Colors.white,
      child: ListTile(
        leading: Icon(Icons.access_time, color: Colors.orange[700]),
        title: Text(
          language == 'english' ? 'Notification Time' : 'Nguva yeZviziviso',
          style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
        ),
        subtitle: Text(
          _notificationTime.format(context),
          style: TextStyle(
            color: _isDarkMode ? Colors.white70 : Colors.black54,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.edit),
        onTap: () async {
          final time = await showTimePicker(
            context: context,
            initialTime: _notificationTime,
          );
          if (time != null) {
            setState(() => _notificationTime = time);
            await VerseOfDayService.instance.updateSettings(time: time);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    language == 'english'
                        ? 'Notification time updated to ${time.format(context)}'
                        : 'Nguva yezviziviso yachinjwa kuita ${time.format(context)}',
                  ),
                ),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildVerseOfDayActions() {
    final language = _settingsService.selectedLanguage;

    return Card(
      color: _isDarkMode ? Colors.grey[800] : Colors.white,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.refresh, color: Colors.blue[700]),
            title: Text(
              language == 'english'
                  ? 'Refresh Today\'s Verse'
                  : 'Vandudzira Vhesi raZuva',
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Text(
              language == 'english'
                  ? 'Get a new random verse for today'
                  : 'Wana vhesi rasarudzwa muzuva ranhasi',
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            onTap: () async {
              await VerseOfDayService.instance.refreshTodaysVerse();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      language == 'english'
                          ? 'Today\'s verse refreshed!'
                          : 'Vhesi razuva ravandudzwa!',
                    ),
                  ),
                );
              }
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.visibility, color: Colors.green[700]),
            title: Text(
              language == 'english'
                  ? 'Show Today\'s Verse'
                  : 'Ratidza Vhesi reZuva',
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Text(
              language == 'english'
                  ? 'View the current verse of the day'
                  : 'Ona vhesi rezuva ranhasi',
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            onTap: () {
              VerseOfDayService.instance.showVerseOfDayPopup(context);
            },
          ),
          const Divider(height: 1),
          /*// NEW TEST NOTIFICATION BUTTON
          ListTile(
            leading: Icon(
              Icons.notifications_active,
              color: Colors.orange[700],
            ),
            title: Text(
              language == 'english' ? 'Test Notification' : 'Yedza Zviziviso',
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Text(
              language == 'english'
                  ? 'Send a test notification to verify it\'s working'
                  : 'Tumira yekuyedza kuti uone kana zvichishanda',
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            trailing: Icon(Icons.send, color: Colors.orange[700], size: 20),
            onTap: () async {
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            language == 'english'
                                ? 'Sending test notification...'
                                : 'Kutumira yekuyedza...',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              try {
                // Send test notification
                await VerseOfDayService.instance.testNotification();

                // Close loading indicator
                if (mounted) Navigator.of(context).pop();

                // Show success message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        language == 'english'
                            ? '✅ Test notification sent! Check your notification panel.'
                            : '✅ Yekuyedza yatumirwa! Tarisa pazviziviso zvako.',
                      ),
                      backgroundColor: Colors.green[700],
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              } catch (e) {
                // Close loading indicator
                if (mounted) Navigator.of(context).pop();

                // Show error message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        language == 'english'
                            ? '❌ Failed to send test notification: ${e.toString()}'
                            : '❌ Tatadza kutumira yekuyedza: ${e.toString()}',
                      ),
                      backgroundColor: Colors.red[700],
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
          ),*/
        ],
      ),
    );
  }

  // Your existing settings widgets remain the same...
  Widget _buildFontSizeSlider() {
    return Card(
      color: _isDarkMode ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Font Size: ${_fontSize.toInt()}px',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _fontSize,
              min: 12.0,
              max: 24.0,
              divisions: 12,
              activeColor: Colors.blue[700],
              onChanged: (value) {
                setState(() {
                  _fontSize = value;
                });
                _settingsService.setFontSize(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle() {
    return Card(
      color: _isDarkMode ? Colors.grey[800] : Colors.white,
      child: SwitchListTile(
        title: Text(
          'Dark Mode',
          style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
        ),
        subtitle: Text(
          _isDarkMode ? 'Dark theme enabled' : 'Light theme enabled',
          style: TextStyle(
            color: _isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        value: _isDarkMode,
        activeThumbColor: Colors.blue[700],
        onChanged: (bool value) async {
          setState(() {
            _isDarkMode = value;
          });
          await _settingsService.setDarkMode(value);

          // Update colors based on theme
          if (value) {
            _selectedTextColor = Colors.white;
            _selectedBackgroundColor = Colors.grey[900]!;
          } else {
            _selectedTextColor = Colors.black87;
            _selectedBackgroundColor = Colors.white;
          }
          await _settingsService.setTextColor(_selectedTextColor);
          await _settingsService.setBackgroundColor(_selectedBackgroundColor);
        },
      ),
    );
  }

  Widget _buildTextColorPicker() {
    final colors = [
      Colors.black87,
      Colors.white,
      Colors.blue[800]!,
      Colors.green[800]!,
      Colors.brown[800]!,
      Colors.purple[800]!,
    ];

    return Card(
      color: _isDarkMode ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Text Color',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: colors.map((color) {
                return GestureDetector(
                  onTap: () async {
                    setState(() {
                      _selectedTextColor = color;
                    });
                    await _settingsService.setTextColor(color);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(
                        color: _selectedTextColor == color
                            ? Colors.blue[700]!
                            : Colors.grey[300]!,
                        width: _selectedTextColor == color ? 3 : 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundColorPicker() {
    final colors = [
      Colors.white,
      Colors.grey[900]!,
      Colors.blue[50]!,
      Colors.green[50]!,
      Colors.orange[50]!,
      Colors.purple[50]!,
    ];

    return Card(
      color: _isDarkMode ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Background Color',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: colors.map((color) {
                return GestureDetector(
                  onTap: () async {
                    setState(() {
                      _selectedBackgroundColor = color;
                    });
                    await _settingsService.setBackgroundColor(color);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(
                        color: _selectedBackgroundColor == color
                            ? Colors.blue[700]!
                            : Colors.grey[300]!,
                        width: _selectedBackgroundColor == color ? 3 : 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final progressPercentage = _settingsService.getReadingProgressPercentage();
    final lastChapter = _settingsService.lastReadChapter;
    final lastVerse = _settingsService.lastReadVerse;

    return Card(
      color: _isDarkMode ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reading Progress',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progressPercentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
            ),
            const SizedBox(height: 8),
            Text(
              '${progressPercentage.toInt()}% complete',
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last read: Chapter $lastChapter, Verse $lastVerse',
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueReadingButton() {
    return Card(
      color: _isDarkMode ? Colors.grey[800] : Colors.white,
      child: ListTile(
        leading: Icon(Icons.play_arrow, color: Colors.blue[700]),
        title: Text(
          'Continue Reading',
          style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
        ),
        subtitle: Text(
          'Chapter ${_settingsService.lastReadChapter}',
          style: TextStyle(
            color: _isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.chapterDetail,
            arguments: _settingsService.lastReadChapter,
          );
        },
      ),
    );
  }

  Widget _buildBookmarksCard() {
    final bookmarks = _settingsService.getBookmarksList();

    return Card(
      color: _isDarkMode ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bookmarks',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  '${bookmarks.length} saved',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
            if (bookmarks.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'No bookmarks yet. Tap the bookmark icon while reading to save verses.',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              ...bookmarks.take(3).map((bookmark) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Chapter ${bookmark['chapter']}, Verse ${bookmark['verse']}',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                );
              }),
              if (bookmarks.length > 3)
                Text(
                  '... and ${bookmarks.length - 3} more',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white70 : Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Card(
      color: _selectedBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _selectedTextColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This is how your text will look while reading. The font size is ${_fontSize.toInt()}px and you can see the color scheme you\'ve selected.',
              style: TextStyle(
                fontSize: _fontSize,
                height: 1.5,
                color: _selectedTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetSettings() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'This will reset all settings to default values. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _settingsService.resetAllSettings();
      // Reset verse of day settings too
      await VerseOfDayService.instance.updateSettings(
        enabled: true,
        time: const TimeOfDay(hour: 8, minute: 0),
      );
      await _loadSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings reset to default')),
        );
      }
    }
  }
}
