import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  
  @override
  State<RegisterPage> createState() => _RegisterPageState();
  
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
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
              controller: userNameController,
              decoration: InputDecoration(
                labelText: 'Felhasználónév',
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
              style: TextStyle(color: Colors.white, fontSize: 15),
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
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
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
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
              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Siker"),
                    content: const Text("Sikeres regisztráció"),
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
          style: FilledButton.styleFrom(backgroundColor: Color.fromARGB(255, 85, 173, 78), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
          child: const Text("Regisztráció", style: TextStyle(fontSize: 18, color: Colors.white), textAlign: TextAlign.center),
        ),
        ),
        ],
      ),
      backgroundColor: Color.fromARGB(255, 58, 58, 58)
    );
  }
}