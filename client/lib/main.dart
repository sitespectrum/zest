import 'package:flutter/material.dart';
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import 'package:flutter_localizations/flutter_localizations.dart';
import "package:functional_widget_annotation/functional_widget_annotation.dart";
import "package:provider/provider.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:zest_client/providers/language_provider.dart";
import 'package:zest_client/providers/workout_provider.dart';
import "package:zest_client/servers.dart";

import "login_page.dart";
import "pages.dart";
import "register_page.dart";

part "main.g.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final prefs = await SharedPreferences.getInstance();
  apiUrl = (await getSelectedInstance()).baseUrl;
  final savedUsername = prefs.getString('username');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
      ],
      child: MyApp(initialUsername: savedUsername),
    ),
  );
}

@hwidget
Widget myApp(BuildContext context, {String? initialUsername}) {
  final lang = Provider.of<LanguageProvider>(context);

  return MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: lang.currentLocale,
    localeResolutionCallback: (deviceLocale, supportedLocales) {
      if (deviceLocale != null) {
        for (var locale in supportedLocales) {
          if (locale.languageCode == deviceLocale.languageCode) {
            return deviceLocale;
          }
        }
      }
      return supportedLocales.first;
    },
    supportedLocales: const [Locale('en'), Locale('hu')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Color.fromARGB(255, 20, 20, 20),
      fontFamily: 'Geist',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 20, 20, 20),
        surfaceTintColor: Colors.transparent,
      ),
    ),
    home: initialUsername != null ? Pages() : Scaffold(body: MainPage()),
  );
}

@hwidget
Widget mainPage(BuildContext context) {
  final lang = Provider.of<LanguageProvider>(context);
  final screenHeight = MediaQuery.of(context).size.height;

  return Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.1),

              Center(
                child: Image.asset(
                  'assets/icon/Zest_logo.png',
                  width: 200,
                  height: 200,
                ),
              ),

              SizedBox(height: screenHeight * 0.1),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 85, 173, 78),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  lang.getText('register_button_main'),
                  style: TextStyle(fontSize: 17, color: Colors.white),
                ),
              ),

              const SizedBox(height: 12),

              FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 85, 173, 78),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  lang.getText('login_button_main'),
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
