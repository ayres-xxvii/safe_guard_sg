import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'shared_layer/shared_scaffold.dart';
import 'providers/app_language.dart';

class LanguagesPage extends StatelessWidget {
  const LanguagesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appLanguage = Provider.of<AppLanguage>(context);
    final l10n = AppLocalizations.of(context);
    
    // Fallback strings in case l10n is null
    final heading = l10n?.languagePageHeading ?? "Choose your preferred language";
    final englishText = l10n?.english ?? "English";
    final mandarinText = l10n?.mandarin ?? "Mandarin";
    final malayText = l10n?.malay ?? "Malay";
    final tamilText = l10n?.tamil ?? "Tamil";
    
    return SharedScaffold(
      currentIndex: -1, // Not part of the main navigation
      appBar: AppBar(
        title: Text(heading),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              heading,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildLanguageOption(
              context,
              title: englishText,
              locale: const Locale('en'),
              appLanguage: appLanguage,
            ),
            _buildLanguageOption(
              context,
              title: mandarinText,
              locale: const Locale('zh'),
              appLanguage: appLanguage,
            ),
            _buildLanguageOption(
              context,
              title: malayText,
              locale: const Locale('ms'),
              appLanguage: appLanguage,
            ),
            _buildLanguageOption(
              context,
              title: tamilText,
              locale: const Locale('ta'),
              appLanguage: appLanguage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context, {
    required String title,
    required Locale locale,
    required AppLanguage appLanguage,
  }) {
    final isSelected = appLanguage.appLocale.languageCode == locale.languageCode;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: isSelected ? 4 : 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: isSelected 
          ? const Icon(Icons.check_circle, color: Colors.blue)
          : const Icon(Icons.circle_outlined),
        onTap: () async {
          await appLanguage.changeLanguage(locale);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Language changed to $title'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }
}