import 'dart:convert';
import 'package:client/constants.dart' as constants;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  String l = constants.localroute;
  String s = constants.serverroute;
  final caloriestypeController = TextEditingController();
  late Future<double> calorieGoal;


  @override
  void initState() {
    super.initState();
    _loadUser();
    _checkLoginStatus();
    calorieGoal = fetchCalorieGoal();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString("username");
    setState(() {
      loggedIn = username != null && username.isNotEmpty;
    });
  }

  Future<double> fetchCalorieGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) throw Exception("Nincs token");

    final response = await http.get(
      Uri.parse("$s/api/auth/getUser"), // s || l
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['calorieGoal'] as num).toDouble();
    } else {
      throw Exception("Nem sikerült lekérni a cél kalóriát: ${response.body}");
    }
  }

  Future<void> updateCalorieGoal(double newGoal) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception("Nincs token");

    final response = await http.put(
      Uri.parse("$s/api/auth/updateCalorieGoal"), // s || l
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"calorieGoal": newGoal}),
    );

    if (response.statusCode != 200) {
      throw Exception("Nem sikerült frissíteni a kalóriacélt: ${response.body}");
    }
  }

  void _saveNewGoal() async {
    final newCalories = double.tryParse(caloriestypeController.text);

    if (newCalories == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Adj meg egy érvényes számot!")),
      );
      return;
    }

    try {
      await updateCalorieGoal(newCalories);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kalóriacél frissítve!")),
      );
      setState(() {
        calorieGoal = fetchCalorieGoal();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hiba történt: $e")),
      );
    }
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

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MainPage()),
    );
  }

  void _login() {
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
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
                onPressed: _saveNewGoal,
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
                  "Mentés",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
