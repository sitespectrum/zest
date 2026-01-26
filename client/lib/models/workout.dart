class ExerciseDto {
  final int id;
  final String name;
  final String nameHu;
  final String force;
  final String forceHu;
  final String level;
  final String levelHu;
  final String mechanic;
  final String mechanicHu;
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
  List<WorkoutSetDto> sets = [];

  String getName(String langCode) {
    if (langCode == 'hu') return nameHu.isNotEmpty ? nameHu : name;
    return name;
  }

  List<String> getInstructions(String langCode) {
    if (langCode == 'hu') {
      return instructionsHu.isNotEmpty ? instructionsHu : instructions;
    }
    return instructions;
  }

  List<String> getPMuscles(String langCode) {
    if (langCode == 'hu') {
      return primaryMusclesHu.isNotEmpty ? primaryMusclesHu : primaryMuscles;
    }
    return primaryMuscles;
  }

  String getForce(String langCode) {
    if (langCode == 'hu') return forceHu.isNotEmpty ? forceHu : force;
    return force;
  }

  String getLevel(String langCode) {
    if (langCode == 'hu') return levelHu.isNotEmpty ? levelHu : level;
    return level;
  }

  String getMechanic(String langCode) {
    if (langCode == 'hu') return mechanicHu.isNotEmpty ? mechanicHu : mechanic;
    return mechanic;
  }

  String getEquipment(String langCode) {
    if (langCode == 'hu') {
      return equipmentHu.isNotEmpty ? equipmentHu : equipment;
    }
    return equipment;
  }

  String getCategory(String langCode) {
    if (langCode == 'hu') return categoryHu.isNotEmpty ? categoryHu : category;
    return category;
  }

  List<String> getSMuscles(String langCode) {
    if (langCode == 'hu') {
      return secondaryMusclesHu.isNotEmpty
          ? secondaryMusclesHu
          : secondaryMuscles;
    }
    return secondaryMuscles;
  }

  ExerciseDto({
    required this.id,
    required this.name,
    required this.nameHu,
    required this.force,
    required this.forceHu,
    required this.level,
    required this.levelHu,
    required this.mechanic,
    required this.mechanicHu,
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
    this.sets = const [],
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
      force: json['force'] ?? '',
      forceHu: json['forceHu'] ?? '',
      level: json['level'] ?? '',
      levelHu: json['levelHu'] ?? '',
      mechanic: json['mechanic'] ?? '',
      mechanicHu: json['mechanicHu'] ?? '',
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
      sets: [],
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
    'sets': sets.map((e) => e.toJson()).toList(),
  };

  ExerciseDto copyWith({int? id}) {
    return ExerciseDto(
      id: id ?? this.id,
      name: name ?? name,
      nameHu: nameHu ?? nameHu,
      force: force ?? force,
      forceHu: forceHu ?? forceHu,
      level: level ?? level,
      levelHu: levelHu ?? levelHu,
      mechanic: mechanic ?? mechanic,
      mechanicHu: mechanicHu ?? mechanicHu,
      equipment: equipment ?? equipment,
      equipmentHu: equipmentHu ?? equipmentHu,
      category: category ?? category,
      categoryHu: categoryHu ?? categoryHu,
      primaryMuscles: primaryMuscles ?? primaryMuscles,
      primaryMusclesHu: primaryMusclesHu ?? primaryMusclesHu,
      secondaryMuscles: secondaryMuscles ?? secondaryMuscles,
      secondaryMusclesHu: secondaryMusclesHu ?? secondaryMusclesHu,
      instructions: instructions ?? instructions,
      instructionsHu: instructionsHu ?? instructionsHu,
      images: images ?? images,
      metValue: metValue ?? metValue,
    );
  }
}

class WorkoutSetDto {
  double weight;
  int reps;
  bool isCompleted;

  WorkoutSetDto({this.weight = 0.0, this.reps = 0, this.isCompleted = false});

  factory WorkoutSetDto.fromJson(Map<String, dynamic> json) {
    return WorkoutSetDto(
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      reps: json['reps'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'weight': weight, 'reps': reps, 'isCompleted': isCompleted};
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
  final String customName;
  final DateTime date;
  final double totalLiftedWeight;
  final int totalBurntCalories;
  final int durationMinutes;
  final List<WorkoutExerciseDto> exercises;

  UserWorkoutDto({
    required this.id,
    required this.userId,
    required this.workoutName,
    required this.customName,
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
      customName: json['customName']?.toString() ?? '',
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
      'customName': customName,
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
  final String customName;
  final DateTime date;
  final double totalLiftedWeight;
  final int totalBurntCalories;
  final int durationMinutes;
  final List<WorkoutExerciseDto> exercises;

  CustomUserWorkoutDto({
    required this.id,
    required this.userId,
    required this.customName,
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
      customName: json['customName'] ?? '',
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
      'customName': customName,
      'date': date.toIso8601String(),
      'totalLiftedWeight': totalLiftedWeight,
      'totalBurntCalories': totalBurntCalories,
      'durationMinutes': durationMinutes,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }
}
