import 'dart:convert';
import 'package:client/components/ui/custom_button.dart';
import 'package:client/components/ui/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'package:client/providers/language_provider.dart';

class FriendProfilePage extends StatefulWidget {
  final int friendId;
  final String friendName;
  final String? friendImage;

  const FriendProfilePage({
    super.key,
    required this.friendId,
    required this.friendName,
    this.friendImage,
  });

  @override
  State<FriendProfilePage> createState() => _FriendProfilePageState();
}

class _FriendProfilePageState extends State<FriendProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> workouts = [];
  List<dynamic> meals = [];
  List<dynamic> friends = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchFriendData();
    fetchFriends();
  }

  Future<void> fetchFriends() async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse("$apiUrl/api/Friends/list"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            friends = jsonDecode(response.body);
          });
        }
      }
    } catch (e) {}
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<void> fetchFriendData() async {
    setState(() => isLoading = true);
    final token = await _getToken();
    if (token == null) return;

    try {
      final workoutRes = await http.get(
        Uri.parse(
          "$apiUrl/api/Workout/getFriendCustomWorkouts/${widget.friendId}",
        ),
        headers: {"Authorization": "Bearer $token"},
      );

      final mealRes = await http.get(
        Uri.parse("$apiUrl/api/Meals/getFriendCustomMeals/${widget.friendId}"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (mounted) {
        setState(() {
          if (workoutRes.statusCode == 200) {
            workouts = jsonDecode(workoutRes.body);
          }
          if (mealRes.statusCode == 200) {
            meals = jsonDecode(mealRes.body);
          }
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    CustomSnackbar.show(context, message, backgroundColor: Colors.green);
  }

  Future<void> importWorkout(dynamic workout, LanguageProvider lang) async {
    final token = await _getToken();
    if (token == null) return;

    final requestBody = {
      "userId": 0,
      "customName": "${workout['customName']} (Copy)",
      "date": null,
      "durationMinutes": workout['durationMinutes'],
      "caloriesBurnt": workout['totalBurntCalories'],
      "totalVolume": workout['totalLiftedWeight'],
      "isCustom": true,
      "exercises": (workout['exercises'] as List).map((e) {
        return {
          "exerciseId": e['exerciseId'],
          "name": e['exercise']['name'],
          "sets": (e['sets'] as List).map((s) {
            return {
              "weight": s['weight'],
              "reps": s['reps'],
              "distance": s['distance'],
              "durationSeconds": s['durationSeconds'],
              "isCompleted": false,
            };
          }).toList(),
        };
      }).toList(),
    };

    try {
      final response = await http.post(
        Uri.parse("$apiUrl/api/Workout/AddWorkoutS"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(requestBody),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          _showMessage(lang.getText("workout_saved"));
        } else {
          _showMessage(
            "${lang.getText("error_occurred")}: ${response.statusCode}",
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) _showMessage(lang.getText("error_occurred"), isError: true);
    }
  }

  Future<void> importMeal(dynamic meal, LanguageProvider lang) async {
    final token = await _getToken();
    if (token == null) return;

    final requestBody = {
      "customName": "${meal['customName']} (Copy)",
      "userId": 0,
      "eatenAt": null,
      "isCustom": true,
      "meals": (meal['meals'] as List).map((m) {
        return {
          "foodId": m['foodId'],
          "name": m['name'],
          "quantity": m['quantity'],
          "calories": m['calories'],
          "protein": m['proteins'],
          "carbs": m['carbs'],
          "fat": m['fat'],
          "unit": m['unit'],
          "baseWeight": m['baseWeight'],
        };
      }).toList(),
    };

    try {
      final response = await http.post(
        Uri.parse("$apiUrl/api/Meals/addGroupS"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(requestBody),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          _showMessage(lang.getText("meal_saved"));
        } else {
          _showMessage(
            "${lang.getText("error_occurred")}: ${response.statusCode}",
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) _showMessage(lang.getText("error_occurred"), isError: true);
    }
  }

  Future<void> sendRequest(int userId) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final token = await _getToken();
    if (token == null) return;

    final response = await http.post(
      Uri.parse("$apiUrl/api/Friends/request/$userId"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      CustomSnackbar.show(
        context,
        lang.getText("request_sent"),
        backgroundColor: Colors.green,
      );
    } else {
      CustomSnackbar.show(
        context,
        "${lang.getText("error_occurred")}: ${response.body}",
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 30, 30, 30),
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green,
              backgroundImage:
                  (widget.friendImage != null && widget.friendImage!.isNotEmpty)
                  ? MemoryImage(base64Decode(widget.friendImage!))
                  : null,
              child: (widget.friendImage == null || widget.friendImage!.isEmpty)
                  ? const Icon(Icons.person, size: 20, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              widget.friendName,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            margin: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color.fromARGB(50, 64, 255, 50),
              border: Border.all(
                color: const Color.fromARGB(100, 64, 255, 50),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TabBar(
              controller: _tabController,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              splashFactory: NoSplash.splashFactory,
              indicator: BoxDecoration(
                color: const Color.fromARGB(100, 64, 255, 50),
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(16),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              dividerHeight: 0,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.green,
              tabs: [
                Tab(text: lang.getText("workout_templates")),
                Tab(text: lang.getText("meal_templates")),
              ],
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : TabBarView(
              controller: _tabController,
              children: [_buildWorkoutList(lang), _buildMealList(lang)],
            ),

      bottomNavigationBar:
          friends.any(
            (f) =>
                f['id'] == widget.friendId ||
                f['friendId'] == widget.friendId ||
                f['userId'] == widget.friendId,
          )
          ? null
          : SafeArea(
              child: Container(
                margin: EdgeInsets.all(20),
                child: CustomButton(
                  onPressed: () {
                    sendRequest(widget.friendId);
                  },
                  title: lang.getText("send_friend_request"),
                  iconData: Icons.group_add_sharp,
                ),
              ),
            ),
    );
  }

  Widget _buildWorkoutList(LanguageProvider lang) {
    if (workouts.isEmpty) {
      return Center(
        child: Text(
          lang.getText("no_public_workouts"),
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }
    return ListView.builder(
      itemCount: workouts.length,
      itemBuilder: (context, index) {
        final w = workouts[index];
        final String name =
            (w['customName'] == null || w['customName'].toString().isEmpty)
            ? lang.getText("anonymous_workout")
            : w['customName'];

        return Card(
          color: const Color.fromARGB(255, 45, 45, 45),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: const Icon(Icons.fitness_center, color: Colors.green),
            title: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              "${w['exercises'].length} ${lang.getText("exercises_count")} • ${w['durationMinutes']} ${lang.getText("minutes")}",
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.download, color: Colors.blueAccent),
              onPressed: () => importWorkout(w, lang),
              tooltip: lang.getText("save_to_my_templates"),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMealList(LanguageProvider lang) {
    if (meals.isEmpty) {
      return Center(
        child: Text(
          lang.getText("no_public_meals"),
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }
    return ListView.builder(
      itemCount: meals.length,
      itemBuilder: (context, index) {
        final m = meals[index];
        final String name =
            (m['customName'] == null || m['customName'].toString().isEmpty)
            ? lang.getText("anonymous_meal")
            : m['customName'];

        return Card(
          color: const Color.fromARGB(255, 45, 45, 45),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: const Icon(Icons.restaurant_menu, color: Colors.orange),
            title: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              "${m['totalCalories']} kcal • ${m['meals'].length} ${lang.getText("ingredients_count")}",
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.download, color: Colors.blueAccent),
              onPressed: () => importMeal(m, lang),
              tooltip: lang.getText("save_to_my_templates"),
            ),
          ),
        );
      },
    );
  }
}
