class UserDto {
  final int id;
  final String userName;
  final int height;
  final int weight;
  final DateTime birth;
  final String gender;
  final String goal;
  final String activity;
  final double calorieGoal;

  UserDto({
    required this.id,
    required this.userName,
    required this.height,
    required this.weight,
    required this.birth,
    required this.gender,
    required this.goal,
    required this.activity,
    required this.calorieGoal,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] ?? 0,
      userName: json['userName'] ?? '',
      height: json['height'] ?? 0,
      weight: json['weight'] ?? 0,
      birth: DateTime.parse(json['birth']),
      gender: json['gender'] ?? '',
      goal: json['goal'] ?? '',
      activity: json['activity'] ?? '',
      calorieGoal: (json['calorieGoal'] ?? 0).toDouble(),
    );
  }
}

class MealDto {
  final String foodId;
  final String name;
  final String? piece;
  int calories;
  double protein;
  double carbs;
  double fat;
  int quantity;
  String? unit;
  double? baseWeight;
  double? multiplier;
  int? cmultiplier;

  MealDto({
    required this.foodId,
    required this.name,
    this.piece,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.quantity = 1,
    this.unit,
    this.baseWeight,
    this.multiplier,
    this.cmultiplier,
  });

  int get qCalories => (calories * quantity);
  double get qProtein => (protein * quantity);
  double get qCarbs => (carbs * quantity);
  double get qFat => (fat * quantity);

  static String _firstNonNull(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      if (json.containsKey(k) && json[k] != null) return json[k].toString();
    }
    return '';
  }

  static String _cleanNumberString(String s) {
    var t = s.trim();
    final m = RegExp(r'[-+]?\d+[.,]?\d*').firstMatch(t);
    if (m != null) return m.group(0)!.replaceAll(',', '.');
    return '0';
  }

  factory MealDto.fromJson(Map<String, dynamic> json) {
    final fid = _firstNonNull(json, ['foodId', 'food_id', 'id', 'obj_id']);
    final name = _firstNonNull(json, ['name', 'title']) ?? 'Ismeretlen';
    String unit = _firstNonNull(json, ['unit']);

    final calRaw = _firstNonNull(json, ['calories', 'cal', 'kcal_and_unit']);
    final protRaw = _firstNonNull(json, ['protein', 'proteins']);
    final carbsRaw = _firstNonNull(json, ['carbo', 'carbs', 'carbohydrate']);
    final fatRaw = _firstNonNull(json, ['fat', 'fats']);
    final quantityRaw = _firstNonNull(json, ['quantity', 'amount', 'count']);

    int calories = int.tryParse(_cleanNumberString(calRaw)) ?? 0;
    double protein = double.tryParse(_cleanNumberString(protRaw)) ?? 0.0;
    double carbs = double.tryParse(_cleanNumberString(carbsRaw)) ?? 0.0;
    double fat = double.tryParse(_cleanNumberString(fatRaw)) ?? 0.0;
    int quantity = int.tryParse(quantityRaw) ?? 1;

    return MealDto(
      foodId: fid,
      name: name,
      piece: _firstNonNull(json, ['piece', 'unit', 'pictitle']).isEmpty
          ? null
          : _firstNonNull(json, ['piece', 'unit', 'pictitle']),
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      quantity: quantity,
      unit: unit,
      baseWeight: (json['baseWeight'] ?? 0).toDouble(),
      multiplier: (json['multiplier'] ?? 1).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    "foodId": foodId,
    "name": name,
    "piece": piece ?? "",
    "calories": calories,
    "protein": protein,
    "carbs": carbs,
    "fat": fat,
    "quantity": quantity,
    "unit": unit,
    "baseWeight": baseWeight,
    "multiplier": multiplier,
  };
}

class UserMealDto {
  final int id;
  final String mealName;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final DateTime eatenAt;
  final List<MealDto> meals;

  UserMealDto({
    required this.id,
    required this.mealName,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.eatenAt,
    required this.meals,
  });

  static String _firstNonNull(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      if (json.containsKey(k) && json[k] != null) return json[k].toString();
    }
    return '';
  }

  static String _cleanNumberString(String s) {
    var t = s.trim();
    final m = RegExp(r'[-+]?\d+[.,]?\d*').firstMatch(t);
    if (m != null) return m.group(0)!.replaceAll(',', '.');
    return '0';
  }

  factory UserMealDto.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return UserMealDto(
      id: json['id'],
      mealName: json['mealName'],
      totalCalories: (json['totalCalories'] ?? 0).toDouble(),
      totalProtein: (json['totalProtein'] ?? 0).toDouble(),
      totalCarbs: (json['totalCarbs'] ?? 0).toDouble(),
      totalFat: (json['totalFat'] ?? 0).toDouble(),
      eatenAt: DateTime.parse(json['eatenAt']),
      meals: (json['meals'] as List<dynamic>)
          .map((e) => MealDto.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "mealName": mealName,
      "calories": totalCalories,
      "protein": totalProtein,
      "carbs": totalCarbs,
      "fat": totalFat,
      "eatenAt": eatenAt.toIso8601String(),
      "meals": meals,
    };
  }
}
