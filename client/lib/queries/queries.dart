import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zest_client/models/meal.dart';
import 'package:zest_client/models/workout.dart';
import 'package:zest_client/queries/wrappers.dart';
import 'package:zest_client/servers.dart';

final userMealsQuery = buildQueryArgs(
  queryKey: ["user", "meals", "all"],
  queryFn: (context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) throw Exception("Nincs token");

    final response = await http.get(
      Uri.parse("$apiUrl/api/meals/getUserMeals"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => UserMealDto.fromJson(e)).toList();
    } else {
      throw Exception(response.body);
    }
  },
);

final userCustomMealsQuery = buildQueryArgs(
  queryKey: ["user", "customMeals", "all"],
  queryFn: (context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) throw Exception("Nincs token");

    final response = await http.get(
      Uri.parse("$apiUrl/api/meals/getCustomUserMeals"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => CustomUserMealDto.fromJson(e)).toList();
    } else {
      throw Exception("Failed to fetch user custom meals: ${response.body}");
    }
  },
);

final calorieGoalQuery = buildQueryArgs(
  queryKey: ["user", "calorieGoal"],
  queryFn: (context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception("Nincs token");

    final response = await http.get(
      Uri.parse("$apiUrl/api/auth/getUser"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final goal = data['calorieGoal'] ?? data['CalorieGoal'];
      return (goal as num).toDouble();
    } else {
      throw Exception(response.body);
    }
  },
);

final totalCaloriesTodayQuery = buildQueryArgs(
  queryKey: ["user", "meals", "totalCaloriesToday"],
  queryFn: (context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception("Nincs token");

    final response = await http.get(
      Uri.parse("$apiUrl/api/meals/getTodayCalories"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data as num).toDouble();
    } else {
      throw Exception(response.body);
    }
  },
);

final userWorkoutsQuery = buildQueryArgs(
  queryKey: ["user", "workouts", "all"],
  queryFn: (context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) throw Exception("Nincs token");

    final response = await http.get(
      Uri.parse("$apiUrl/api/workout/getUserWorkouts"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => UserWorkoutDto.fromJson(e)).toList();
    } else {
      throw Exception(response.body);
    }
  },
);
