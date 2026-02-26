import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  late Locale _currentLocale;

  @override
  void initState() {
    super.initState();
    _currentLocale = context.locale;
  }

  void _changeLanguage(Locale locale) {
    context.setLocale(locale);
    setState(() => _currentLocale = locale);
    // 延迟关闭页面，让语言切换生效
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('语言设置'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '选择语言',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text('简体中文'),
                    subtitle: const Text('Chinese Simplified'),
                    trailing: _currentLocale.languageCode == 'zh'
                        ? const Icon(Icons.check_circle, color: Colors.blue)
                        : null,
                    onTap: () => _changeLanguage(const Locale('zh', 'CN')),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text('English'),
                    subtitle: const Text('English'),
                    trailing: _currentLocale.languageCode == 'en'
                        ? const Icon(Icons.check_circle, color: Colors.blue)
                        : null,
                    onTap: () => _changeLanguage(const Locale('en', 'US')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '语言设置已立即生效',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
