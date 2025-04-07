  import 'package:flutter/material.dart';
  import 'package:flutter_gen/gen_l10n/app_localizations.dart';

  class LanguageSelectButtonActive extends StatelessWidget {
    const LanguageSelectButtonActive({
      super.key,
      required this.text,
    });

    final String text;

    @override
    Widget build(BuildContext context) {
      return ElevatedButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 30),
          backgroundColor: Color.fromARGB(255, 115, 211, 209),
        ),
        child: Text(text, style: TextStyle(fontSize: 30, color: Colors.white)),
      );
    }
  }

  class LanguageSelectButton extends StatelessWidget {
    const LanguageSelectButton({
      super.key,
      required this.text,
      required this.onPressed,
    });

    final String text;
    final VoidCallback onPressed;

    @override
    Widget build(BuildContext context) {
      return TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
        ),
        child: Text(text, style: const TextStyle(fontSize: 30, color: Colors.black87)),
      );
    }
  }

  class LanguagesPage extends StatefulWidget {
    @override
    _LanguagesPageState createState() => _LanguagesPageState();
  }

  class _LanguagesPageState extends State<LanguagesPage> {
    int active = 1;
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()), // Handle loading state
      );
    }

    var languages = <String>[
      localizations.english,
      localizations.mandarin,
      localizations.malay,
      localizations.tamil,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Languages')),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 30, bottom: 60),
              child: Text(
                localizations.languagePageHeading,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = 0; i < languages.length; i++)
                  i == active
                      ? LanguageSelectButtonActive(text: languages[i])
                      : LanguageSelectButton(
                          text: languages[i],
                          onPressed: () {
                            setState(() {
                              active = i;
                            });
                          },
                        ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  }