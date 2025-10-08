class MealDto {
  final String foodId;
  final String name;
  final String? piece;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  MealDto({
    required this.foodId,
    required this.name,
    this.piece,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
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

  factory MealDto.fromJson(Map<String, dynamic> json) {
    final fid = _firstNonNull(json, ['foodId', 'food_id', 'id', 'obj_id']);
    final name = _firstNonNull(json, ['name', 'title']) ?? 'Ismeretlen';

    final calRaw = _firstNonNull(json, ['calories', 'cal', 'kcal_and_unit']);
    final protRaw = _firstNonNull(json, ['protein', 'proteins']);
    final carbsRaw = _firstNonNull(json, ['carbo', 'carbs', 'carbohydrate']);
    final fatRaw = _firstNonNull(json, ['fat', 'fats']);

    final calories = int.tryParse(_cleanNumberString(calRaw)) ?? 0;
    final protein = double.tryParse(_cleanNumberString(protRaw)) ?? 0.0;
    final carbs = double.tryParse(_cleanNumberString(carbsRaw)) ?? 0.0;
    final fat = double.tryParse(_cleanNumberString(fatRaw)) ?? 0.0;

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
  };
}

class UserMealDto {
  final int id;
  final String mealName;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime eatenAt;

  UserMealDto({
    required this.id,
    required this.mealName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.eatenAt,
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
      id: parseInt(json['id']),
      mealName: json['mealName'] ?? json['MealName'] ?? 'Ismeretlen',
      calories: parseDouble(
        json['calories'] ?? json['Calories'] ?? json['totalCalories'],
      ),
      protein: parseDouble(
        json['protein'] ?? json['Protein'] ?? json['totalProtein'],
      ),
      carbs: parseDouble(json['carbs'] ?? json['Carbs'] ?? json['totalCarbs']),
      fat: parseDouble(json['fat'] ?? json['Fat'] ?? json['totalFat']),
      eatenAt: DateTime.parse(json['eatenAt'] ?? json['EatenAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "mealName": mealName,
      "calories": calories,
      "protein": protein,
      "carbs": carbs,
      "fat": fat,
      "eatenAt": eatenAt.toIso8601String(),
    };
  }
}
