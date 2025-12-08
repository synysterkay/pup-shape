import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pupshape/models/meal_plan.dart';

class PlanProvider with ChangeNotifier {
  WeightLossPlan? _currentPlan;
  DailyMealPlan? _selectedDayPlan;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  WeightLossPlan? get currentPlan => _currentPlan;
  DailyMealPlan? get selectedDayPlan => _selectedDayPlan;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  bool get hasPlan => _currentPlan != null;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Load the active plan for a dog
  Future<void> loadPlan(String dogId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore
          .collection('plans')
          .where('dogId', isEqualTo: dogId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (doc.docs.isNotEmpty) {
        _currentPlan = WeightLossPlan.fromMap(doc.docs.first.data());
        _loadDayPlan(_selectedDate);
      }
    } catch (e) {
      debugPrint('Error loading plan: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save a new plan to Firestore
  Future<void> savePlan(WeightLossPlan plan) async {
    try {
      await _firestore.collection('plans').doc(plan.id).set(plan.toMap());
      _currentPlan = plan;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving plan: $e');
      rethrow;
    }
  }

  /// Select a specific date to view its meal plan
  void selectDate(DateTime date) {
    _selectedDate = date;
    _loadDayPlan(date);
    notifyListeners();
  }

  /// Load the meal plan for a specific date
  void _loadDayPlan(DateTime date) {
    if (_currentPlan == null) {
      _selectedDayPlan = null;
      return;
    }

    // Find the plan for this date
    final dayIndex = date.difference(_currentPlan!.startDate).inDays;
    if (dayIndex >= 0 && dayIndex < _currentPlan!.dailyPlans.length) {
      _selectedDayPlan = _currentPlan!.dailyPlans[dayIndex];
    } else {
      _selectedDayPlan = null;
    }
  }

  /// Mark a meal as logged
  Future<void> logMeal(String mealId) async {
    if (_selectedDayPlan == null || _currentPlan == null) return;

    try {
      // Update local state
      final mealIndex = _selectedDayPlan!.meals.indexWhere((m) => m.id == mealId);
      if (mealIndex != -1) {
        _selectedDayPlan!.meals[mealIndex].isLogged = true;
        
        // Update Firestore
        await _firestore.collection('plans').doc(_currentPlan!.id).update({
          'dailyPlans': _currentPlan!.dailyPlans.map((p) => p.toMap()).toList(),
        });
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error logging meal: $e');
    }
  }

  /// Get meal plan for a specific date range (for calendar view)
  List<DailyMealPlan> getMealPlansForWeek(DateTime startOfWeek) {
    if (_currentPlan == null) return [];

    final plans = <DailyMealPlan>[];
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final dayIndex = date.difference(_currentPlan!.startDate).inDays;
      
      if (dayIndex >= 0 && dayIndex < _currentPlan!.dailyPlans.length) {
        plans.add(_currentPlan!.dailyPlans[dayIndex]);
      }
    }
    return plans;
  }

  /// Generate a mock plan (for testing without DeepSeek)
  WeightLossPlan generateMockPlan(String dogId, double currentWeight, double targetWeight) {
    final startDate = DateTime.now();
    final endDate = startDate.add(const Duration(days: 84)); // 12 weeks
    
    // Varied meal options for rotation
    final breakfastOptions = [
      {'name': 'Chicken & Rice', 'calories': 380, 'portion': '200g', 'ingredients': ['Chicken breast', 'Brown rice', 'Fish oil']},
      {'name': 'Turkey & Quinoa', 'calories': 370, 'portion': '195g', 'ingredients': ['Ground turkey', 'Quinoa', 'Carrots']},
      {'name': 'Beef & Oatmeal', 'calories': 390, 'portion': '205g', 'ingredients': ['Lean beef', 'Oatmeal', 'Pumpkin']},
      {'name': 'Salmon & Barley', 'calories': 375, 'portion': '200g', 'ingredients': ['Salmon', 'Barley', 'Broccoli']},
      {'name': 'Duck & Sweet Potato', 'calories': 385, 'portion': '200g', 'ingredients': ['Duck breast', 'Sweet potato', 'Spinach']},
      {'name': 'Lamb & Rice', 'calories': 380, 'portion': '200g', 'ingredients': ['Lamb', 'White rice', 'Green beans']},
      {'name': 'Chicken & Pasta', 'calories': 370, 'portion': '195g', 'ingredients': ['Chicken thigh', 'Whole wheat pasta', 'Peas']},
    ];
    
    final dinnerOptions = [
      {'name': 'Salmon & Sweet Potato', 'calories': 380, 'portion': '200g', 'ingredients': ['Salmon', 'Sweet potato', 'Green beans']},
      {'name': 'Beef & Vegetables', 'calories': 385, 'portion': '200g', 'ingredients': ['Ground beef', 'Mixed vegetables', 'Brown rice']},
      {'name': 'Turkey & Pumpkin', 'calories': 375, 'portion': '195g', 'ingredients': ['Turkey', 'Pumpkin', 'Quinoa']},
      {'name': 'Chicken & Broccoli', 'calories': 370, 'portion': '195g', 'ingredients': ['Chicken', 'Broccoli', 'Rice']},
      {'name': 'Fish & Potato', 'calories': 380, 'portion': '200g', 'ingredients': ['White fish', 'Potato', 'Carrots']},
      {'name': 'Pork & Apple', 'calories': 385, 'portion': '200g', 'ingredients': ['Pork loin', 'Apple', 'Sweet potato']},
      {'name': 'Venison & Berries', 'calories': 390, 'portion': '205g', 'ingredients': ['Venison', 'Blueberries', 'Brown rice']},
    ];
    
    final treatOptions = [
      {'name': 'Healthy Snacks', 'calories': 190, 'portion': '50g', 'ingredients': ['Carrots', 'Dental chews']},
      {'name': 'Training Treats', 'calories': 185, 'portion': '45g', 'ingredients': ['Freeze-dried liver', 'Apple slices']},
      {'name': 'Dental Chews', 'calories': 195, 'portion': '55g', 'ingredients': ['Dental sticks', 'Sweet potato chips']},
      {'name': 'Veggie Mix', 'calories': 180, 'portion': '50g', 'ingredients': ['Green beans', 'Cucumber', 'Carrot sticks']},
      {'name': 'Fruit Treats', 'calories': 190, 'portion': '50g', 'ingredients': ['Banana', 'Blueberries', 'Watermelon']},
      {'name': 'Protein Bites', 'calories': 200, 'portion': '55g', 'ingredients': ['Chicken jerky', 'Cheese cubes']},
      {'name': 'Frozen Treats', 'calories': 185, 'portion': '50g', 'ingredients': ['Frozen yogurt drops', 'Pumpkin']},
    ];
    
    final dailyPlans = <DailyMealPlan>[];
    for (int day = 0; day < 84; day++) {
      final date = startDate.add(Duration(days: day));
      
      // Rotate through meal options with some variation
      final breakfastIndex = day % breakfastOptions.length;
      final dinnerIndex = day % dinnerOptions.length;
      final treatIndex = day % treatOptions.length;
      
      final breakfast = breakfastOptions[breakfastIndex];
      final dinner = dinnerOptions[dinnerIndex];
      final treat = treatOptions[treatIndex];
      
      dailyPlans.add(DailyMealPlan(
        date: date,
        dayNumber: day + 1,
        targetCalories: 950,
        notes: day % 7 == 0 ? 'Week ${(day ~/ 7) + 1} - Stay consistent!' : null,
        meals: [
          PlannedMeal(
            id: 'breakfast_$day',
            mealType: 'breakfast',
            foodName: breakfast['name'] as String,
            calories: breakfast['calories'] as int,
            portion: breakfast['portion'] as String,
            ingredients: List<String>.from(breakfast['ingredients'] as List),
          ),
          PlannedMeal(
            id: 'dinner_$day',
            mealType: 'dinner',
            foodName: dinner['name'] as String,
            calories: dinner['calories'] as int,
            portion: dinner['portion'] as String,
            ingredients: List<String>.from(dinner['ingredients'] as List),
          ),
          PlannedMeal(
            id: 'treats_$day',
            mealType: 'treats',
            foodName: treat['name'] as String,
            calories: treat['calories'] as int,
            portion: treat['portion'] as String,
            ingredients: List<String>.from(treat['ingredients'] as List),
          ),
        ],
      ));
    }

    return WeightLossPlan(
      id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
      dogId: dogId,
      startDate: startDate,
      endDate: endDate,
      startWeight: currentWeight,
      targetWeight: targetWeight,
      durationWeeks: 12,
      dailyCalories: 950,
      macros: {
        'protein': '25-30%',
        'fat': '12-15%',
        'carbs': '40-45%',
      },
      dailyPlans: dailyPlans,
      createdAt: DateTime.now(),
    );
  }
}
