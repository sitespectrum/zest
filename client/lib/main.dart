import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import "LoginPage.dart";
import "RegisterPage.dart";

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const appTitle = 'Zest';
    return MaterialApp(
      title: appTitle,
      home: Scaffold(
        appBar: AppBar(title: const Text(appTitle)),
        body: const MyCustomForm(),
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
        Center(
          child: FilledButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RegisterPage()),
              );
            },
            child: const Text("Még nincs fiókod? Regisztráció"),
            style: FilledButton.styleFrom(backgroundColor: Colors.lightGreen[600])
          ),
        ),

        Center(
          child: FilledButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            child: const Text("Már van fiókod? Bejelentkezés"),
            style: FilledButton.styleFrom(backgroundColor: Colors.lightGreen[600])
          ),
        )
      ],
    );
  }
}