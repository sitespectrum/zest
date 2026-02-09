import 'package:flutter/material.dart';
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import 'package:flutter_localizations/flutter_localizations.dart';
import "package:functional_widget_annotation/functional_widget_annotation.dart";
import "package:provider/provider.dart";
import "package:shared_preferences/shared_preferences.dart";
import 'package:zest_client/components/drawers/login_drawer.dart';
import 'package:zest_client/components/drawers/register_drawer.dart';
import "package:zest_client/components/topo_background.dart";
import "package:zest_client/components/ui/custom_button.dart";
import 'package:zest_client/pages.dart';
import "package:zest_client/providers/language_provider.dart";
import 'package:zest_client/providers/workout_provider.dart';
import "package:zest_client/servers.dart";

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
      colorScheme: ColorScheme.dark(),
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
  return Scaffold(
    body: Stack(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white38, Colors.transparent],
          ).createShader(bounds),
          child: Container(
            color: const Color.fromARGB(60, 64, 255, 50),
            child: Opacity(
              opacity: 0.35,
              child: TopoBackground(
                foreground: const Color.fromARGB(255, 64, 255, 50),
                scale: 2.5,
                speed: 0.75,
              ),
            ),
          ),
        ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Flex(
                direction: Axis.vertical,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 24,
                    children: [
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadiusGeometry.circular(16),
                          child: Image.asset(
                            'assets/icon/Zest_logo.png',
                            width: 64,
                            height: 64,
                          ),
                        ),
                      ),
                      Text(
                        "Zest",
                        style: TextStyle(
                          fontSize: 48,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: EdgeInsetsGeometry.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 12,
                      children: [
                        CustomButton(
                          onPressed: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => RegisterDrawer(),
                          ),
                          title: "Get started!",
                          iconData: Icons.fitness_center_rounded,
                        ),

                        CustomButton(
                          onPressed: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => LoginDrawer(),
                          ),
                          title: "Already have an account",
                          iconData: Icons.person_rounded,
                          variant: CustomButtonVariant.secondary,
                        ),
                      ],
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
