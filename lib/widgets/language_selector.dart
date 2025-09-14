// widgets/language_selector.dart

import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/book_service.dart';

class LanguageSelector extends StatefulWidget {
  final VoidCallback? onLanguageChanged;

  const LanguageSelector({super.key, this.onLanguageChanged});

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  final SettingsService _settingsService = SettingsService.instance;
  String _currentLanguage = 'shona';
  bool _isChangingLanguage = false;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    await _settingsService.init();
    if (mounted) {
      setState(() {
        _currentLanguage = _settingsService.selectedLanguage;
      });
    }
  }

  Future<void> _showLanguageDialog() async {
    // Reload current language before showing dialog
    await _loadLanguage();

    final selectedLanguage = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Text('🇿🇼'),
                title: const Text('Shona'),
                subtitle: const Text('chiShona'),
                selected: _currentLanguage == 'shona',
                onTap: () => Navigator.of(context).pop('shona'),
              ),
              ListTile(
                leading: const Text('🇬🇧'),
                title: const Text('English'),
                subtitle: const Text('English'),
                selected: _currentLanguage == 'english',
                onTap: () => Navigator.of(context).pop('english'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selectedLanguage != null && selectedLanguage != _currentLanguage) {
      await _changeLanguage(selectedLanguage);
    }
  }

  Future<void> _changeLanguage(String newLanguage) async {
    // Show loading indicator
    setState(() {
      _isChangingLanguage = true;
    });

    try {
      print(
        '🔍 DEBUG: LanguageSelector - Changing language from $_currentLanguage to $newLanguage',
      );

      // Update the language setting and wait for it to complete
      await _settingsService.setLanguage(newLanguage);

      // Force a complete reload of the book service
      await BookService.instance.reloadBook();

      // Update local state
      if (mounted) {
        setState(() {
          _currentLanguage = newLanguage;
        });
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newLanguage == 'english'
                  ? 'Language changed to English'
                  : 'Mutauro wakachinjidzwa kuenda kuchiShona',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Call the callback with a slight delay to ensure everything is updated
      if (widget.onLanguageChanged != null) {
        await Future.delayed(const Duration(milliseconds: 200));
        widget.onLanguageChanged!();
      }

      print(
        '🔍 DEBUG: LanguageSelector - Language change completed successfully',
      );
    } catch (e) {
      print('❌ ERROR: Failed to change language: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change language: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChangingLanguage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChangingLanguage) {
      return Container(
        padding: const EdgeInsets.all(8),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      );
    }

    return GestureDetector(
      onTap: _showLanguageDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _currentLanguage == 'english' ? 'ENG' : 'SHO',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}
