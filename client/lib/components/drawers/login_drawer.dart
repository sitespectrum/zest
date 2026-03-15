import 'dart:convert';
import 'package:client/components/ui/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client/components/ui/custom_button.dart';
import 'package:client/components/ui/custom_drawer.dart';
import 'package:client/constants.dart';
import 'package:client/pages.dart';
import 'package:client/providers/language_provider.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class LoginDrawer extends StatefulWidget {
  const LoginDrawer({super.key});

  @override
  State<LoginDrawer> createState() => _LoginDrawerState();
}

class _LoginDrawerState extends State<LoginDrawer> {
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isChecked = false;

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
              CustomTextField(
                _userNameController,
                lang.getText("username_hint"),
              ),

              CustomTextField(
                _passwordController,
                lang.getText("password_hint"),
                isPassword: isChecked ? false : true,
                iconButton: IconButton(
                  onPressed: () => isChecked
                      ? setState(() {
                          isChecked = false;
                        })
                      : setState(() {
                          isChecked = true;
                        }),
                  icon: Icon(Icons.remove_red_eye),
                ),
              ),
              SizedBox(height: 5),
            ],
          ),

          CustomButton(
            onPressed: () async {
              final username = _userNameController.text;
              final email = _emailController.text;
              final password = _passwordController.text;

              try {
                final response = await http.post(
                  Uri.parse('$apiUrl/api/auth/login'),
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

                  String responseUsername = json['username'];

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('jwt_token', token);
                  await prefs.setString('refresh_token', refreshToken);
                  await prefs.setString('username', responseUsername);
                  await prefs.setInt('userId', userId);
                  OneSignal.login(userId.toString());

                  print('Token mentve: $token');
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Pages()),
                    );
                  }
                } else {
                  String errorMessage = "Ismeretlen hiba történt.";

                  if (response.body.isNotEmpty) {
                    try {
                      final errorData = jsonDecode(response.body);
                      errorMessage =
                          errorData['message'] ??
                          errorData['title'] ??
                          response.body;
                    } catch (_) {
                      errorMessage = response.body;
                    }
                  }

                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: const Color.fromARGB(255, 30, 30, 30),
                        title: const Text(
                          "Sikertelen bejelentkezés",
                          style: TextStyle(color: Colors.white),
                        ),
                        content: Text(
                          errorMessage,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "OK",
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: const Color.fromARGB(255, 30, 30, 30),
                      title: const Text(
                        "Hálózati hiba",
                        style: TextStyle(color: Colors.white),
                      ),
                      content: Text(
                        "Nem sikerült kapcsolódni a szerverhez: $e",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "OK",
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
            title: lang.getText("login"),
            iconData: Icons.login_rounded,
          ),
        ],
      ),
    );
  }
}
