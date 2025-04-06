import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  _LanguagePageState createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  String? _selectedLanguage;

  // This function will save the selected language in shared preferences
  Future<void> _saveLanguagePreference(String language) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
  }

  // This function will handle when the OK button is pressed
  void _onOkPressed() {
    if (_selectedLanguage != null) {
      // Save the selected language to shared preferences
      _saveLanguagePreference(_selectedLanguage!);
      Navigator.pop(context); // Go back to the previous page
    } else {
      // Optionally show an error message if no language is selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a language')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Language"),
        backgroundColor: const Color(0xFF73D3D0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: const Text("English"),
              onTap: () {
                setState(() {
                  _selectedLanguage = "English";
                });
              },
              selected: _selectedLanguage == "English",
            ),
            ListTile(
              title: const Text("Chinese"),
              onTap: () {
                setState(() {
                  _selectedLanguage = "Chinese";
                });
              },
              selected: _selectedLanguage == "Chinese",
            ),
            ListTile(
              title: const Text("Malay"),
              onTap: () {
                setState(() {
                  _selectedLanguage = "Malay";
                });
              },
              selected: _selectedLanguage == "Malay",
            ),
            ListTile(
              title: const Text("Tamil"),
              onTap: () {
                setState(() {
                  _selectedLanguage = "Tamil";
                });
              },
              selected: _selectedLanguage == "Tamil",
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
            const Text(
              "Please select your preferred language.",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}