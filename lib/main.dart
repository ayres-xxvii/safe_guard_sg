import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'home.dart'; // Import the second file

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeGuardSG',
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: Locale('en'),
      supportedLocales: [
        Locale('en'), // English
        Locale('zh'), // Mandarin
        Locale('ms'), // Malay
        Locale('ta'), // Tamil
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'SafeGuardSG'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Welcome to SafeGuardSG!'),
            const SizedBox(height: 20),
            ElevatedButton(
            onPressed: () {
                Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MainPage()),
                );
            },
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
            ),
            child: const Text('Get Started'),
            ),

            ElevatedButton(
                onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LanguagesPage()),
                );
                },
                style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Languages'),
            )
        ],
        ),
      ),
    );
  }


}

// New Page (Main Page)
class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Page'),
      ),
      body: const Center(
        child: Text('Welcome to the Main Page!', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}


class LanguageSelectButtonActive extends StatelessWidget {
    const LanguageSelectButtonActive({
        super.key,
        required this.text
    });

    final String text;

    @override
    Widget build(BuildContext context) {
        return ElevatedButton(
            onPressed: () {},
            style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                backgroundColor: Color.fromARGB(255, 115, 211, 209)
            ),
            child: Text(text, style: TextStyle(fontSize: 30, color: Colors.white)),
        );
    }
}
class LanguageSelectButton extends StatelessWidget {
  const LanguageSelectButton({
    super.key,
    required this.text,
    required this.onPressed
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

// Languages Page
class LanguagesPage extends StatefulWidget {
    @override
    _LanguagesPageState createState() => _LanguagesPageState();
}

class _LanguagesPageState extends State<LanguagesPage> {
    int active = 1;

    @override
    Widget build(BuildContext context) {

        var languages = <String> [
            AppLocalizations.of(context)!.english,
            AppLocalizations.of(context)!.mandarin,
            AppLocalizations.of(context)!.malay,
            AppLocalizations.of(context)!.tamil
        ];
        return Scaffold(
            appBar: AppBar(title: const Text('Languages')), 
            body: Center(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                    Padding(
                        padding: const EdgeInsets.only(top: 30, bottom: 60),
                            child: Text(AppLocalizations.of(context)!.languagePageHeading, textAlign: TextAlign.center, style: const TextStyle(
                            fontSize: 24,
                        ))
                    ),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                            for (int i=0; i<languages.length; i++)
                                i == active ?
                                LanguageSelectButtonActive(text: languages[i]) :
                                LanguageSelectButton(text: languages[i], onPressed: () {
                                    setState(() {
                                        active = i;
                                    });
                                },)
                        ],
                    )
                ],
                
            ),
            ),
        );
    }
}
