import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zest_client/components/ui/custom_button.dart';
import 'package:zest_client/components/ui/custom_drawer.dart';
import 'package:zest_client/constants.dart';
import 'package:zest_client/pages.dart';
import 'package:zest_client/providers/language_provider.dart';

class LoginDrawer extends StatefulWidget {
  const LoginDrawer({super.key});

  @override
  State<LoginDrawer> createState() => _LoginDrawerState();
}

class _LoginDrawerState extends State<LoginDrawer> {
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return CustomDrawer(
      child: Column(
        spacing: 24,
        children: [
          Column(
            spacing: 12,
            children: [
              TextField(
                cursorColor: Colors.white,
                style: TextStyle(color: Colors.white, fontSize: 15),
                controller: _userNameController,
                decoration: InputDecoration(
                  fillColor: const Color(0xFF272727),
                  filled: true,
                  labelText: lang.getText('username_and_email_hint'),
                  labelStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: const Color.fromARGB(100, 64, 255, 50),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white.withAlpha(20),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              TextField(
                cursorColor: Colors.white,
                style: TextStyle(color: Colors.white),
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  fillColor: const Color(0xFF272727),
                  filled: true,
                  labelText: lang.getText('password_hint'),
                  labelStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: const Color.fromARGB(100, 64, 255, 50),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white.withAlpha(20),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),

          CustomButton(
            onPressed: () async {
              final username = _userNameController.text;
              final email = _emailController.text;
              final password = _passwordController.text;

              final response = await http.post(
                Uri.parse('$apiUrl/api/auth/login'), // s || l
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
                print(json);
                final token = json['token'];
                final refreshToken = json['refreshToken'];
                final userId = json['userId'];
                String username = json['username'];

                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('jwt_token', token);
                await prefs.setString('refresh_token', refreshToken);
                await prefs.setString('username', username);
                await prefs.setInt('userId', userId);

                print('Token mentve: $token');
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Pages()),
                  );
                }
              } else {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Hiba"),
                    content: const Text("Hibás email vagy jelszó!"),
                  ),
                );
              }
            },
            title: "Log in",
            iconData: Icons.login_rounded,
          ),
        ],
      ),
    );
  }
}
