import 'dart:async';
import 'package:flutter/material.dart';
import 'package:client/models/workout.dart';

class WorkoutProvider with ChangeNotifier {
  Timer? _timer;

  DateTime? _startTime;

  int _initialOffsetSeconds = 0;
  List<ExerciseDto> _userWorkouts = [];
  bool _isWorkoutActive = false;

  int get totalSeconds {
    if (!_isWorkoutActive || _startTime == null) return _initialOffsetSeconds;
    return _initialOffsetSeconds +
        DateTime.now().difference(_startTime!).inSeconds;
  }

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

    _startTime = DateTime.now();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      notifyListeners();
    });
  }

  void stopWorkout() {
    _timer?.cancel();
    _isWorkoutActive = false;
    _startTime = null;
    _initialOffsetSeconds = 0;
    notifyListeners();
  }

  void updateExercises(List<ExerciseDto> newExercises) {
    _userWorkouts = newExercises;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
