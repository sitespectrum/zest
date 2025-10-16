import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client/login_page.dart';
import 'package:client/main.dart';

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
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
        (route) => false,
      );
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

  final caloriestypeController = TextEditingController();

  @override
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              automaticallyImplyLeading: false,
              backgroundColor: const Color.fromARGB(255, 58, 58, 58),
            ),
          ),
        ),

        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.41,
                    height: MediaQuery.of(context).size.height * 0.085,
                    padding: const EdgeInsets.fromLTRB(6, 4, 10, 5),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 72, 72, 72),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      cursorColor: Colors.white,
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                      controller: caloriestypeController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.transparent,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  Positioned(
                    top: -MediaQuery.of(context).size.height * 0.018,
                    left: MediaQuery.of(context).size.width * 0.025,
                    child: const Text(
                      "Új kalóriacél",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              FilledButton(
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
