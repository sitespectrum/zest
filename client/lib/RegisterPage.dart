import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'LoginPage.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {

    const appTitle = 'Zest';

    return Scaffold(
      appBar: AppBar(
        title: const Text(appTitle),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: TextField(
              controller: userNameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Felhasználónév',
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: TextField(
              controller: emailController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Email',
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Jelszó',
              ),
            ),
          ),

          Center(
          child: FilledButton(
          onPressed: () async {
            print("szia");
            final response = await http.post(
              Uri.parse("http://10.0.2.2:5031/api/auth/register"),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({
                "username": userNameController.text,
                "email": emailController.text,
                "password": passwordController.text,
              }),
            );

            if (response.statusCode == 200 || response.statusCode == 201) {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Siker"),
                  content: const Text("Sikeres regisztráció"),
                ),
              );
            } else {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Hiba"),
                  content: Text("${response.body}"),
                ),
              );
            }
          },
          child: const Text("Regisztráció"),
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
      ),
    );
  }
}