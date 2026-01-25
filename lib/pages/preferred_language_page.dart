import 'package:flutter/material.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:connect/core/utils/ui_utils.dart';

@NowaGenerated()
class PreferredLanguagePage extends StatefulWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const PreferredLanguagePage({super.key});

  @override
  State<PreferredLanguagePage> createState() => _PreferredLanguagePageState();
}

@NowaGenerated()
class _PreferredLanguagePageState extends State<PreferredLanguagePage> {
  final List<String> _selectedLanguages = ['English'];

  final List<_Language> _languages = [
    _Language(name: 'English', nativeName: 'English', flag: '🇬🇧'),
    _Language(name: 'Spanish', nativeName: 'Español', flag: '🇪🇸'),
    _Language(name: 'French', nativeName: 'Français', flag: '🇫🇷'),
    _Language(name: 'German', nativeName: 'Deutsch', flag: '🇩🇪'),
    _Language(name: 'Italian', nativeName: 'Italiano', flag: '🇮🇹'),
    _Language(name: 'Portuguese', nativeName: 'Português', flag: '🇵🇹'),
    _Language(name: 'Russian', nativeName: 'Русский', flag: '🇷🇺'),
    _Language(name: 'Chinese', nativeName: '中文', flag: '🇨🇳'),
    _Language(name: 'Japanese', nativeName: '日本語', flag: '🇯🇵'),
    _Language(name: 'Korean', nativeName: '한국어', flag: '🇰🇷'),
    _Language(name: 'Arabic', nativeName: 'العربية', flag: '🇸🇦'),
    _Language(name: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳'),
  ];

  void _toggleLanguage(String languageName) {
    setState(() {
      if (_selectedLanguages.contains(languageName)) {
        if (_selectedLanguages.length > 1) {
          _selectedLanguages.remove(languageName);
        }
      } else {
        _selectedLanguages.add(languageName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Preferred Languages',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select one or more languages you prefer',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                final language = _languages[index];
                final isSelected = _selectedLanguages.contains(language.name);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _toggleLanguage(language.name),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        child: Row(
                          children: [
                            Text(
                              language.flag,
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    language.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    language.nativeName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                                size: 24,
                              )
                            else
                              Icon(
                                Icons.circle_outlined,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: () {
                  UiUtils.showSuccessSnackBar(
                      'Saved ${_selectedLanguages.length} language(s)');
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Save Preferences',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${_selectedLanguages.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Language {
  final String name;
  final String nativeName;
  final String flag;

  _Language({
    required this.name,
    required this.nativeName,
    required this.flag,
  });
}
