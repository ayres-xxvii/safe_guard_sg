import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // if you used flutterfire CLI
import 'singpass_login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // if using generated options
  );
  // Load saved language preference on app start
  final prefs = await SharedPreferences.getInstance();
  final String? savedLanguage = prefs.getString('language');

  runApp(MyApp(initLocale: savedLanguage != null ? Locale(savedLanguage) : null));
}

class MyApp extends StatefulWidget {
  final Locale? initLocale;

  const MyApp({super.key, this.initLocale});

  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) => 
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  Locale? _locale = Locale('en');

  // Method to change the app's locale
  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });

    // Save preference for next app start
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('language', locale.languageCode);
    });
  }

  @override
  void initState() {
    super.initState();
    _locale = widget.initLocale;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeGuardSG',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4DD0C7)),
        fontFamily: 'Poppins',
      ),
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('zh'), // Mandarin
        Locale('ms'), // Malay
        Locale('ta'), // Tamil
      ],
      home: OnboardingPage(),
    );
  }
}

// Your existing OnboardingPage code stays the same
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4DD0C7),
      body: SafeArea(
        child: Stack(
          children: [
            // Back button
            Positioned(
              top: 20,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () {
                  // Navigation logic if needed
                },
              ),
            ),
            
            Column(
              children: [
                // Logo section
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
Stack(
  alignment: Alignment.center,
  children: [
    // Circle background stays put
    Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
    ),

    // Move logo slightly down (positive Y)
    Transform.translate(
      offset: const Offset(0, 30), // try 10-20px downward
      child: Image.asset(
        'assets/images/safeguardlogo.png',
        width: 550,
        fit: BoxFit.contain,
      ),
    ),
  ],
),


                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                
                // White bottom section
                Expanded(
                  flex: 1,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A37),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Stay informed. Stay safe',
                            style: TextStyle(
                              fontSize: 24,
                              color: Color(0xFF4DD0C7),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                 onPressed: () {
  
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SingpassLoginPage(),
    ),
  );
},
style: ElevatedButton.styleFrom(
  backgroundColor: const Color(0xFFEA1221),
  foregroundColor: Colors.white,
  padding: const EdgeInsets.symmetric(vertical: 15),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(30),
  ),
),

                                  child: const Text(
                                    'Login with Singpass',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Colors.indigo,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Container(
                                    width: 10,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Container(
                                    width: 10,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}