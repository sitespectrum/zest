import 'dart:async';
import 'package:flutter/material.dart';
import 'package:client/models/workout.dart';

class WorkoutProvider with ChangeNotifier {
  Timer? _timer;
  final Stopwatch _stopwatch = Stopwatch();

  int _initialOffsetSeconds = 0;

  List<ExerciseDto> _userWorkouts = [];
  bool _isWorkoutActive = false;

  int get totalSeconds => _initialOffsetSeconds + _stopwatch.elapsed.inSeconds;

  int get seconds => totalSeconds % 60;
  int get minutes => (totalSeconds ~/ 60) % 60;
  int get hours => totalSeconds ~/ 3600;
  int get totalMinutes => totalSeconds ~/ 60;

  bool get isWorkoutActive => _isWorkoutActive;
  List<ExerciseDto> get userWorkouts => _userWorkouts;

  String get formattedTime {
    String s = seconds.toString().padLeft(2, '0');
    String m = minutes.toString().padLeft(2, '0');
    String h = hours.toString().padLeft(2, '0');
    return "$h : $m : $s";
  }

  void startWorkout(List<ExerciseDto> exercises, {int initialSeconds = 0}) {
    if (_isWorkoutActive) {
      _userWorkouts = exercises;
      notifyListeners();
      return;
    }

    _userWorkouts = exercises;
    _isWorkoutActive = true;
    _initialOffsetSeconds = initialSeconds;

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
    _initialOffsetSeconds = 0;
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
