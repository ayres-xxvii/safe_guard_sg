import 'package:flutter/material.dart';
import 'package:safe_guard_sg/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LanguagesPage extends StatefulWidget {
  const LanguagesPage({super.key});

  @override
  _LanguagesPageState createState() => _LanguagesPageState();
}

class _LanguagesPageState extends State<LanguagesPage> {
  String? _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _selectedLanguage = Localizations.localeOf(context).languageCode;
      });
    });
  }

  // This function will save the selected language in shared preferences
  Future<void> _saveLanguagePreference(String language) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
  }

  // This function will handle when the OK button is pressed
  void _onOkPressed() {
    // if (_selectedLanguage != null) {
      // Save the selected language to shared preferences
      _saveLanguagePreference(_selectedLanguage!);
      MyApp.of(context).setLocale(Locale(_selectedLanguage!));
      Navigator.pop(context); // Go back to the previous page
    // } else {
    //   // Optionally show an error message if no language is selected
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Please select a language')),
    //   );
    // }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    Map languages = <String, String>{
      'en': localizations.english,
      'zh': localizations.mandarin,
      'ms': localizations.malay,
      'ta': localizations.tamil,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.languagePageBarTitle),
        // backgroundColor: const Color(0xFF73D3D0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 30, bottom: 30),
              child: Text(
                localizations.languagePageHeading,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
            for (var code in languages.keys)
              code == _selectedLanguage ?
              ListTile(
                title: Center(
                  child: Text(languages[code], style: TextStyle(color: Colors.white),)
                ),
                tileColor: const Color(0xFF73D3D0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                ),
                onTap: () {}
              ) :
              ListTile(
                title: Center(
                  child: Text(languages[code])
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                ),
                onTap: () {
                  setState(() {
                    _selectedLanguage = code;
                    print(_selectedLanguage);
                  });
                }
              ),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: _onOkPressed,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF73D3D0), 
                    shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    ),
                ),
                child: const Text("OK"),
                ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}