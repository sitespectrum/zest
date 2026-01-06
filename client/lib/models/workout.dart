class ExerciseDto {
  final int id;
  final String name;
  final String nameHu;
  final String? force;
  final String? forceHu;
  final String level;
  final String levelHu;
  final String? mechanic;
  final String? mechanicHu;
  final String equipment;
  final String equipmentHu;
  final String category;
  final String categoryHu;
  final List<String> primaryMuscles;
  final List<String> primaryMusclesHu;
  final List<String> secondaryMuscles;
  final List<String> secondaryMusclesHu;
  final List<String> instructions;
  final List<String> instructionsHu;
  final List<String> images;
  final double metValue;

  ExerciseDto({
    required this.id,
    required this.name,
    required this.nameHu,
    this.force,
    this.forceHu,
    required this.level,
    required this.levelHu,
    this.mechanic,
    this.mechanicHu,
    required this.equipment,
    required this.equipmentHu,
    required this.category,
    required this.categoryHu,
    required this.primaryMuscles,
    required this.primaryMusclesHu,
    required this.secondaryMuscles,
    required this.secondaryMusclesHu,
    required this.instructions,
    required this.instructionsHu,
    required this.images,
    required this.metValue,
  });

  factory ExerciseDto.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic list) {
      if (list == null) return [];
      if (list is List) {
        return list.map((e) => e.toString()).toList();
      }
      return [];
    }

    double toDoubleSafe(dynamic val, double defaultValue) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? defaultValue;
      return defaultValue;
    }

    return ExerciseDto(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      nameHu: json['nameHu'] ?? '',
      force: json['force'],
      forceHu: json['forceHu'],
      level: json['level'] ?? '',
      levelHu: json['levelHu'] ?? '',
      mechanic: json['mechanic'],
      mechanicHu: json['mechanicHu'],
      equipment: json['equipment'] ?? '',
      equipmentHu: json['equipmentHu'] ?? '',
      category: json['category'] ?? '',
      categoryHu: json['categoryHu'] ?? '',
      primaryMuscles: parseList(json['primaryMuscles']),
      primaryMusclesHu: parseList(json['primaryMusclesHu']),
      secondaryMuscles: parseList(json['secondaryMuscles']),
      secondaryMusclesHu: parseList(json['secondaryMusclesHu']),
      instructions: parseList(json['instructions']),
      instructionsHu: parseList(json['instructionsHu']),
      images: parseList(json['images']),
      
      metValue: toDoubleSafe(json['metValue'], 3.5),
    );
  }

  Map<String, dynamic> toJson() => {
      'id': id,
      'name': name,
      'nameHu': nameHu,
      'force': force,
      'forceHu': forceHu,
      'level': level,
      'levelHu': levelHu,
      'mechanic': mechanic,
      'mechanicHu': mechanicHu,
      'equipment': equipment,
      'equipmentHu': equipmentHu,
      'category': category,
      'categoryHu': categoryHu,
      'primaryMuscles': primaryMuscles,
      'primaryMusclesHu': primaryMusclesHu,
      'secondaryMuscles': secondaryMuscles,
      'secondaryMusclesHu': secondaryMusclesHu,
      'instructions': instructions,
      'instructionsHu': instructionsHu,
      'images': images,
      'metValue': metValue,
  };
  ExerciseDto copyWith({int? id}) {
    return ExerciseDto(
      id: id ?? this.id,
      name: name ?? this.name,
      nameHu: nameHu ?? this.nameHu,
      force: force ?? this.force,
      forceHu: forceHu ?? this.forceHu,
      level: level ?? this.level,
      levelHu: levelHu ?? this.levelHu,
      mechanic: mechanic ?? this.mechanic,
      mechanicHu: mechanicHu ?? this.mechanicHu,
      equipment: equipment ?? this.equipment,
      equipmentHu: equipmentHu ?? this.equipmentHu,
      category: category ?? this.category,
      categoryHu: categoryHu ?? this.categoryHu,
      primaryMuscles: primaryMuscles ?? this.primaryMuscles,
      primaryMusclesHu: primaryMusclesHu ?? this.primaryMusclesHu,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      secondaryMusclesHu: secondaryMusclesHu ?? this.secondaryMusclesHu,
      instructions: instructions ?? this.instructions,
      instructionsHu: instructionsHu ?? this.instructionsHu,
      images: images ?? this.images,
      metValue: metValue ?? this.metValue,
    );
  }
}

class WorkoutSetDto {
  final int id;
  final int workoutExerciseId;
  final int order;
  final double weight;
  final int reps;
  final bool isWarmup;

  WorkoutSetDto({
    required this.id,
    required this.workoutExerciseId,
    required this.order,
    required this.weight,
    required this.reps,
    required this.isWarmup,
  });

  factory WorkoutSetDto.fromJson(Map<String, dynamic> json) {
    return WorkoutSetDto(
      id: json['id'] ?? 0,
      workoutExerciseId: json['workoutExerciseId'] ?? 0,
      order: json['order'] ?? 0,
      // Biztonságos konverzió: num-ként olvassuk, majd toDouble
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      reps: json['reps'] ?? 0,
      isWarmup: json['isWarmup'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workoutExerciseId': workoutExerciseId,
      'order': order,
      'weight': weight,
      'reps': reps,
      'isWarmup': isWarmup,
    };
  }
}

class WorkoutExerciseDto {
  final int id;
  final int userWorkoutId;
  final int exerciseId;
  final ExerciseDto? exercise;
  final List<WorkoutSetDto> sets;

  WorkoutExerciseDto({
    required this.id,
    required this.userWorkoutId,
    required this.exerciseId,
    this.exercise,
    required this.sets,
  });

  factory WorkoutExerciseDto.fromJson(Map<String, dynamic> json) {
    var setsList = json['sets'] as List?;
    List<WorkoutSetDto> parsedSets = setsList != null
        ? setsList.map((i) => WorkoutSetDto.fromJson(i)).toList()
        : [];
    
    parsedSets.sort((a, b) => a.order.compareTo(b.order));

    return WorkoutExerciseDto(
      id: json['id'] ?? 0,
      userWorkoutId: json['userWorkoutId'] ?? 0,
      exerciseId: json['exerciseId'] ?? 0,
      exercise: json['exercise'] != null
          ? ExerciseDto.fromJson(json['exercise'])
          : null,
      sets: parsedSets,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userWorkoutId': userWorkoutId,
      'exerciseId': exerciseId,
      'exercise': exercise?.toJson(),
      'sets': sets.map((e) => e.toJson()).toList(),
    };
  }
}

class UserWorkoutDto {
  final int id;
  final int userId;
  final String workoutName;
  final DateTime date;
  final double totalLiftedWeight;
  final int totalBurntCalories;
  final int durationMinutes;
  final List<WorkoutExerciseDto> exercises;

  UserWorkoutDto({
    required this.id,
    required this.userId,
    required this.workoutName,
    required this.date,
    required this.totalLiftedWeight,
    required this.totalBurntCalories,
    required this.durationMinutes,
    required this.exercises,
  });

  factory UserWorkoutDto.fromJson(Map<String, dynamic> json) {
    var exList = json['exercises'] as List?;
    List<WorkoutExerciseDto> parsedExercises = exList != null
        ? exList.map((i) => WorkoutExerciseDto.fromJson(i)).toList()
        : [];

    return UserWorkoutDto(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      workoutName: json['workoutName'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      totalLiftedWeight: (json['totalLiftedWeight'] as num?)?.toDouble() ?? 0.0,
      totalBurntCalories: json['totalBurntCalories'] ?? 0,
      durationMinutes: json['durationMinutes'] ?? 0,
      exercises: parsedExercises,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'workoutName': workoutName,
      'date': date.toIso8601String(),
      'totalLiftedWeight': totalLiftedWeight,
      'totalBurntCalories': totalBurntCalories,
      'durationMinutes': durationMinutes,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }
}

class CustomUserWorkoutDto {
  final int id;
  final int userId;
  final String customWorkoutName;
  final DateTime date;
  final double totalLiftedWeight;
  final int totalBurntCalories;
  final int durationMinutes;
  final List<WorkoutExerciseDto> exercises;

  CustomUserWorkoutDto({
    required this.id,
    required this.userId,
    required this.customWorkoutName,
    required this.date,
    required this.totalLiftedWeight,
    required this.totalBurntCalories,
    required this.durationMinutes,
    required this.exercises,
  });

  factory CustomUserWorkoutDto.fromJson(Map<String, dynamic> json) {
    var exList = json['exercises'] as List?;
    List<WorkoutExerciseDto> parsedExercises = exList != null
        ? exList.map((i) => WorkoutExerciseDto.fromJson(i)).toList()
        : [];

    return CustomUserWorkoutDto(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      customWorkoutName: json['workoutName'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      totalLiftedWeight: (json['totalLiftedWeight'] as num?)?.toDouble() ?? 0.0,
      totalBurntCalories: json['totalBurntCalories'] ?? 0,
      durationMinutes: json['durationMinutes'] ?? 0,
      exercises: parsedExercises,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'workoutName': customWorkoutName,
      'date': date.toIso8601String(),
      'totalLiftedWeight': totalLiftedWeight,
      'totalBurntCalories': totalBurntCalories,
      'durationMinutes': durationMinutes,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }
}