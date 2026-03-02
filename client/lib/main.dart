import "dart:convert";
import "dart:math";
import 'components/custom_workout_page.dart';
import "package:client/constants.dart";
import "package:client/providers/language_provider.dart";
import "package:client/components/drawers/login_drawer.dart";
import "package:client/components/drawers/register_drawer.dart";
import "package:client/components/topo_background.dart";
import "package:client/components/ui/custom_button.dart";
import 'package:flutter/material.dart';
import "package:flutter/services.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import 'package:flutter_hooks/flutter_hooks.dart';
import "package:http/http.dart" as http;
import "package:provider/provider.dart";
import "package:shared_preferences/shared_preferences.dart";
import "pages.dart";
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:client/providers/workout_provider.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.Debug.setAlertLevel(OSLogLevel.none);

  OneSignal.initialize(dotenv.env['ONESIGNAL_APP_ID']!);
  OneSignal.Notifications.requestPermission(true);

  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    final data = event.notification.additionalData;

    debugPrint("🚨 ÉRTESÍTÉS ÉRKEZETT AZ ELŐTÉRBEN!");
    debugPrint("🚨 ADATOK: $data");

    if (data != null && data['type'] == 'session_invite') {
      event.preventDefault();
      final sessionId = data['sessionId'];
      final body = event.notification.body ?? "Meghívtak egy edzésre!";

      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            body,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          duration: const Duration(seconds: 15),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF333333),
          action: SnackBarAction(
            label: "ELFOGADOM",
            textColor: Colors.greenAccent,
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('jwt_token');
              final api = dotenv.env[apiUrl];

              try {
                final response = await http.post(
                  Uri.parse("$api/api/WorkoutSession/join"),
                  headers: {
                    "Authorization": "Bearer $token",
                    "Content-Type": "application/json",
                  },
                  body: jsonEncode({"SessionId": sessionId}),
                );

                if (response.statusCode == 200) {
                  await prefs.setString('active_session_id', sessionId);
                  await prefs.setBool('is_host', false);

                  scaffoldMessengerKey.currentState?.showSnackBar(
                    const SnackBar(
                      content: Text("Sikeres csatlakozás!"),
                      backgroundColor: Colors.green,
                    ),
                  );

                  navigatorKey.currentState?.push(
                    MaterialPageRoute(
                      builder: (context) =>
                          CWorkoutPage(selectedDay: DateTime.now()),
                    ),
                  );
                } else {
                  scaffoldMessengerKey.currentState?.showSnackBar(
                    SnackBar(
                      content: Text("Hiba: ${response.body}"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                debugPrint("Hiba a csatlakozáskor: $e");
              }
            },
          ),
        ),
      );
    }
  });

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
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
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
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFF7af970).withOpacity(0.1),
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
              child: TopoBackground(
                foreground: const Color(0xFF7af970),
                scale: 2,
              ),
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
                          isScrollControlled: true,
                          builder: (builder) => RegisterDrawer(),
                        );
                      },
                      title: lang.getText('register_button_main'),
                      iconData: Icons.app_registration,
                      variant: CustomButtonVariant.primary,
                    ),

                    const SizedBox(height: 12),

                    CustomButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (builder) => LoginDrawer(),
                        );
                      },
                      title: lang.getText('login_button_main'),
                      iconData: Icons.login,
                      variant: CustomButtonVariant.secondary,
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
