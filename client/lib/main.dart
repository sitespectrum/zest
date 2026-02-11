import "dart:math";

import "package:client/Providers/language_provider.dart";
import "package:client/components/drawers/login_drawer.dart";
import "package:client/components/drawers/register_drawer.dart";
import "package:client/components/topo_background.dart";
import "package:client/components/ui/custom_button.dart";
import "package:client/components/ui/custom_drawer.dart";
import 'package:flutter/material.dart';
import "package:flutter/services.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import 'package:flutter_hooks/flutter_hooks.dart';
import "package:provider/provider.dart";
import "package:shared_preferences/shared_preferences.dart";
import "login_page.dart";
import "pages.dart";
import "register_page.dart";
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:client/providers/workout_provider.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.Debug.setAlertLevel(OSLogLevel.none);

  OneSignal.initialize(dotenv.env['ONESIGNAL_APP_ID']!);
  OneSignal.Notifications.requestPermission(true);

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final prefs = await SharedPreferences.getInstance();
  final savedUsername = prefs.getString('username');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
      ],
      child: Myapp(initialUsername: savedUsername),
    ),
  );
}

class Myapp extends StatelessWidget {
  final String? initialUsername;
  const Myapp({super.key, this.initialUsername});

  @override
  Widget build(BuildContext context) {
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
        colorScheme: ColorScheme.dark(),
        useMaterial3: true,
        fontFamily: 'Geist',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 58, 58, 58),
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: initialUsername != null ? Pages() : Scaffold(body: MainPage()),
    );
  }
}

class MainPage extends HookWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFF7af970).withOpacity(0.4),
                ],
                transform: GradientRotation(-0.5 * pi),
              ),
            ),
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white24, Colors.transparent],
              ).createShader(bounds),
              child: TopoBackground(foreground: const Color(0xFF7af970)),
            ),
          ),
          SafeArea(
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

                    SizedBox(height: screenHeight * 0.005),

                    Text(
                      "Zest",
                      style: TextStyle(
                        fontSize: 50,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.3),

                    CustomButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (builder) => RegisterDrawer(),
                        );
                      },
                      child: Text(
                        lang.getText('register_button_main'),
                        style: TextStyle(fontSize: 17, color: Colors.white),
                      ),
                    ),

                    const SizedBox(height: 12),

                    CustomButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (builder) => LoginDrawer(),
                        );
                      },
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
        ],
      ),
    );
  }
}
