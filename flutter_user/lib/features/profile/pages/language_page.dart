import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  late String _selectedLanguage;

  final List<Map<String, String>> _languages = [
    {'code': 'zh', 'name': '中文 (简体)', 'native': '中文 (简体)'},
    {'code': 'en', 'name': 'English', 'native': 'English'},
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize _selectedLanguage with the current locale from context
    _selectedLanguage = context.locale.languageCode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('language_settings').tr()),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'select_language',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ).tr(),
          ),
          ..._languages.map(
            (language) => RadioListTile<String>(
              title: Text(language['name']!),
              subtitle: Text(language['native']!),
              value: language['code']!,
              groupValue: _selectedLanguage,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedLanguage = value;
                  });
                  // Change the locale
                  context.setLocale(Locale(value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'language_switched'.tr(args: [language['name']!]),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
