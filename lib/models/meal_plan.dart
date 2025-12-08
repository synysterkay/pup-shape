/// Represents a single meal in the daily plan
class PlannedMeal {
  final String id;
  final String mealType; // 'breakfast', 'dinner', 'treats'
  final String foodName;
  final int calories;
  final String portion; // e.g., "200g Chicken & Rice"
  final List<String> ingredients;
  bool isLogged;

  PlannedMeal({
    required this.id,
    required this.mealType,
    required this.foodName,
    required this.calories,
    required this.portion,
    required this.ingredients,
    this.isLogged = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mealType': mealType,
      'foodName': foodName,
      'calories': calories,
      'portion': portion,
      'ingredients': ingredients,
      'isLogged': isLogged,
    };
  }

  factory PlannedMeal.fromMap(Map<String, dynamic> map) {
    return PlannedMeal(
      id: map['id'] ?? '',
      mealType: map['mealType'] ?? '',
      foodName: map['foodName'] ?? '',
      calories: map['calories'] ?? 0,
      portion: map['portion'] ?? '',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      isLogged: map['isLogged'] ?? false,
    );
  }
}

/// Represents a full day's meal plan
class DailyMealPlan {
  final DateTime date;
  final int dayNumber; // 1-84 (12 weeks)
  final int targetCalories;
  final List<PlannedMeal> meals;
  final String? notes; // Optional tips from AI

  DailyMealPlan({
    required this.date,
    required this.dayNumber,
    required this.targetCalories,
    required this.meals,
    this.notes,
  });

  int get totalCalories => meals.fold(0, (sum, meal) => sum + meal.calories);
  int get loggedCalories => meals.where((m) => m.isLogged).fold(0, (sum, meal) => sum + meal.calories);
  bool get isFullyLogged => meals.every((meal) => meal.isLogged);
  int get progress => meals.isEmpty ? 0 : (meals.where((m) => m.isLogged).length / meals.length * 100).round();

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'dayNumber': dayNumber,
      'targetCalories': targetCalories,
      'meals': meals.map((meal) => meal.toMap()).toList(),
      'notes': notes,
    };
  }

  factory DailyMealPlan.fromMap(Map<String, dynamic> map) {
    return DailyMealPlan(
      date: DateTime.parse(map['date']),
      dayNumber: map['dayNumber'] ?? 1,
      targetCalories: map['targetCalories'] ?? 0,
      meals: (map['meals'] as List).map((m) => PlannedMeal.fromMap(m)).toList(),
      notes: map['notes'],
    );
  }
}

/// Represents the complete 12-week plan
class WeightLossPlan {
  final String id;
  final String dogId;
  final DateTime startDate;
  final DateTime endDate;
  final double startWeight;
  final double targetWeight;
  final int durationWeeks;
  final int dailyCalories;
  final Map<String, dynamic> macros; // protein, fat, carbs percentages
  final List<DailyMealPlan> dailyPlans;
  final DateTime createdAt;

  WeightLossPlan({
    required this.id,
    required this.dogId,
    required this.startDate,
    required this.endDate,
    required this.startWeight,
    required this.targetWeight,
    required this.durationWeeks,
    required this.dailyCalories,
    required this.macros,
    required this.dailyPlans,
    required this.createdAt,
  });

  double get weeklyWeightLoss => (startWeight - targetWeight) / durationWeeks;
  int get totalDays => durationWeeks * 7;
  int get daysCompleted {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0;
    if (now.isAfter(endDate)) return totalDays;
    return now.difference(startDate).inDays;
  }
  int get daysRemaining => totalDays - daysCompleted;
  double get progressPercentage => (daysCompleted / totalDays * 100).clamp(0, 100);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dogId': dogId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'startWeight': startWeight,
      'targetWeight': targetWeight,
      'durationWeeks': durationWeeks,
      'dailyCalories': dailyCalories,
      'macros': macros,
      'dailyPlans': dailyPlans.map((plan) => plan.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WeightLossPlan.fromMap(Map<String, dynamic> map) {
    return WeightLossPlan(
      id: map['id'] ?? '',
      dogId: map['dogId'] ?? '',
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      startWeight: map['startWeight']?.toDouble() ?? 0.0,
      targetWeight: map['targetWeight']?.toDouble() ?? 0.0,
      durationWeeks: map['durationWeeks'] ?? 12,
      dailyCalories: map['dailyCalories'] ?? 0,
      macros: Map<String, dynamic>.from(map['macros'] ?? {}),
      dailyPlans: (map['dailyPlans'] as List).map((p) => DailyMealPlan.fromMap(p)).toList(),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
