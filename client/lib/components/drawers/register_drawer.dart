import 'dart:convert';
import 'package:client/components/ui/custom_textfield.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client/components/details_page.dart';
import 'package:client/components/ui/custom_button.dart';
import 'package:client/components/ui/custom_drawer.dart';
import 'package:client/constants.dart';
import 'package:client/providers/language_provider.dart';

class RegisterDrawer extends StatefulWidget {
  const RegisterDrawer({super.key});

  @override
  State<RegisterDrawer> createState() => _RegisterDrawerState();
}

class _RegisterDrawerState extends State<RegisterDrawer> {
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return customDrawer(
      child: Column(
        spacing: 24,
        children: [
          Column(
            spacing: 12,
            children: [
              CustomTextField(
                userNameController,
                lang.getText("username_hint"),
              ),

              CustomTextField(emailController, lang.getText("email_hint")),

              CustomTextField(
                passwordController,
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
            ],
          ),
          CustomButton(
            onPressed: () async {
              print("szia");
              final response = await http.post(
                Uri.parse("$apiUrl/api/auth/register"),
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({
                  "username": userNameController.text,
                  "email": emailController.text,
                  "password": passwordController.text,
                }),
              );
              if (response.statusCode == 200 || response.statusCode == 201) {
                final data = jsonDecode(response.body);
                final userId = data['UserId'] is int
                    ? data['UserId'] as int
                    : int.parse(data['userId'].toString());

                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt('userId', userId);
                OneSignal.login(userId.toString());

                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailsPage(userId: userId),
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Hiba"),
                      content: Text("${response.body}"),
                    ),
                  );
                }
              }
            },
            title: "Register",
            iconData: Icons.person_add_alt_1_rounded,
          ),
        ],
      ),
    );
  }
}
