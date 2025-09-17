import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Column(
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

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 25, vertical: 16),
            child: TextField(
              cursorColor: Colors.white,
              style: TextStyle(color: Colors.white, fontSize: 15),
              controller: _userNameController,
              decoration: InputDecoration(
                fillColor: Color.fromARGB(255, 72, 72, 72),
                labelText: 'Felhasználónév / Email',
                labelStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.grey,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.grey,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 25, vertical: 16),
            child: TextField(
              cursorColor: Colors.white,
              style: TextStyle(color: Colors.white),
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                fillColor: Color.fromARGB(255, 72, 72, 72),
                labelText: "Jelszó",
                labelStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.grey,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.grey,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).size.height * 0.02),

          Center(
            child: FilledButton(
              onPressed: () async {
                final username = _userNameController.text;
                final email = _emailController.text;
                final password = _passwordController.text;

                final response = await http.post(
                  Uri.parse('http://10.0.2.2:5031/api/auth/login'),
                  headers: <String, String>{
                    'Content-Type': 'application/json; charset=UTF-8',
                  },
                  body: jsonEncode(<String, String>{
                    'username': username,
                    'email': email,
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
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HomePage(username: _userNameController.text)),
                    );
                  }
                } else {
                  print('Login failed: ${response.statusCode}');
                }
              },
              style: FilledButton.styleFrom(backgroundColor: Color.fromARGB(255, 85, 173, 78), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
              child: const Text("Bejelentkezés", style: TextStyle(fontSize: 18, color: Colors.white), textAlign: TextAlign.center),
            ),
          )
        ],
      ),
      backgroundColor: Color.fromARGB(255, 58, 58, 58)
    );
  }
}