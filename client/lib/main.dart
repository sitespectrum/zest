import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import "login_page.dart";
import "register_page.dart";

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.dark,
      home: Scaffold(
        body: const MyCustomForm(),
        backgroundColor: Color.fromARGB(255, 58, 58, 58)
      ),
    );
  }
}

class MyCustomForm extends HookWidget {
  const MyCustomForm({super.key});

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[

        SizedBox(height: MediaQuery.of(context).size.height * 0.10),
        
        Center(
          child: Image.asset(
            'assets/icon/Zest_logo.png',
            width: 200,
            height: 200,
          ),
        ),

        SizedBox(height: MediaQuery.of(context).size.height * 0.10),

        Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RegisterPage()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color.fromARGB(255, 85, 173, 78), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
            child: const Text("Még nincs fiókod? Regisztráció", style: TextStyle(fontSize: 18, color: Colors.white), textAlign: TextAlign.center),
          ),
        ),

        SizedBox(height: MediaQuery.of(context).size.height * 0.01),

        Center(
          child: FilledButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Color.fromARGB(255, 85, 173, 78), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
            child: const Text("Már van fiókod? Bejelentkezés", style: TextStyle(fontSize: 18, color: Colors.white), textAlign: TextAlign.center),
          ),
        )
      ],
    );
  }
}