import 'package:flutter/material.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  String _selectedLanguage = 'zh'; // Default to Chinese

  final List<Map<String, String>> _languages = [
    {'code': 'zh', 'name': '中文 (简体)', 'native': '中文 (简体)'},
    {'code': 'zh-TW', 'name': '中文 (繁体)', 'native': '中文 (繁體)'},
    {'code': 'en', 'name': 'English', 'native': 'English'},
    {'code': 'ja', 'name': '日本語', 'native': '日本語'},
    {'code': 'ko', 'name': '한국어', 'native': '한국어'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('语言设置')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '选择语言',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
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
                  // TODO: Implement language change
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('语言已切换到: ${language['name']}')),
                  );
                }
              },
            ),
          ),

          const Divider(),

          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '注意事项',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '语言设置将在下次启动应用时生效。部分内容可能需要重新加载。',
              style: TextStyle(
                color: Color.fromARGB(255, 142, 106, 106),
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Apply Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: () {
                // TODO: Save language preference and restart app
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('语言设置已保存，重启应用后生效')),
                );
              },
              child: const Text('应用设置'),
            ),
          ),
        ],
      ),
    );
  }
}
