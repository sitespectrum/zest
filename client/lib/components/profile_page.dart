import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? username;
  bool loggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString("username");
    setState(() {
      loggedIn = username != null && username.isNotEmpty;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("username");
    await prefs.remove("accessToken");
    await prefs.remove("refreshToken");

    setState(() {
      loggedIn = false;
      username = null;
    });

    if (context.mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  void _login() {
    if (context.mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }

    _checkLoginStatus();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString("username");
    });
  }

  Widget build(BuildContext context) {
    final appTitle = username != null ? 'Üdv, $username!' : 'Üdv!';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.all(6),
            child: AppBar(
              title: Text(
                appTitle,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              automaticallyImplyLeading: false,
              backgroundColor: Color.fromARGB(255, 58, 58, 58),
            ),
          ),
        ),

        Stack(
          children: [
            Center(
              child: FilledButton(
                onPressed: loggedIn ? _logout : _login,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 85, 173, 78),
                  fixedSize: Size(
                    MediaQuery.of(context).size.width * 0.50,
                    MediaQuery.of(context).size.height * 0.07,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: Text(
                  loggedIn ? "Kijelentkezés" : "Bejelentkezés",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
