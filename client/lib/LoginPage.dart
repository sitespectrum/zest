import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'HomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
              controller: _userNameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Felhasználónév',
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: TextField(
              controller: _passwordController,
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
                final username = _userNameController.text;
                final password = _passwordController.text;

                // Login
                final response = await http.post(
                  Uri.parse('http://10.0.2.2:5031/api/auth/login'),
                  headers: <String, String>{
                    'Content-Type': 'application/json; charset=UTF-8',
                  },
                  body: jsonEncode(<String, String>{
                    'username': username,
                    'password': password,
                  }),
                );

                if (response.statusCode == 200) {
                  final json = jsonDecode(response.body);
                  final token = json['token'];
                  final refreshToken = json['refreshToken'];

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('jwt_token', token);
                  await prefs.setString('refresh_token', refreshToken);


                  print('Token mentve: $token');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage(username: _userNameController.text)),
                  );
                } else {
                  print('Login failed: ${response.statusCode}');
                }
              },
              child: const Text("Bejelentkezés"),
              style: FilledButton.styleFrom(backgroundColor: Colors.lightGreen[600]),
            ),
          )
        ],
      ),
    );
  }
}