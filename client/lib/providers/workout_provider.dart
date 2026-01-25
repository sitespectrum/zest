import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zest_client/models/workout.dart';

class WorkoutProvider with ChangeNotifier {
  Timer? _timer;
  final Stopwatch _stopwatch = Stopwatch();

  List<ExerciseDto> _userWorkouts = [];
  bool _isWorkoutActive = false;

  int get seconds => _stopwatch.elapsed.inSeconds % 60;
  int get minutes => _stopwatch.elapsed.inMinutes % 60;
  int get hours => _stopwatch.elapsed.inHours;
  int get totalMinutes => _stopwatch.elapsed.inMinutes;
  bool get isWorkoutActive => _isWorkoutActive;
  List<ExerciseDto> get userWorkouts => _userWorkouts;

  String get formattedTime {
    final duration = _stopwatch.elapsed;
    String s = (duration.inSeconds % 60).toString().padLeft(2, '0');
    String m = (duration.inMinutes % 60).toString().padLeft(2, '0');
    String h = (duration.inHours).toString().padLeft(2, '0');
    return "$h : $m : $s";
  }

  void startWorkout(List<ExerciseDto> exercises) {
    if (_isWorkoutActive) {
      _userWorkouts = exercises;
      notifyListeners();
      return;
    }

    _userWorkouts = exercises;
    _isWorkoutActive = true;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      notifyListeners();
    });

    _stopwatch.reset();
    _stopwatch.start();
  }

  void stopWorkout() {
    _timer?.cancel();
    _isWorkoutActive = false;
    _stopwatch.stop();
    notifyListeners();
  }

  void updateExercises(List<ExerciseDto> newExercises) {
    _userWorkouts = newExercises;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _timer?.cancel();
    super.dispose();
  }
}
