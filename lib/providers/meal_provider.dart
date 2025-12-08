import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pupshape/models/meal.dart';
import 'package:pupshape/models/food_product.dart';
import 'package:pupshape/services/nutrition_service.dart';

class MealProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NutritionService _nutritionService = NutritionService();

  List<Meal> _meals = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<Meal> get meals => _meals;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  
  // Get meals for today
  List<Meal> get todaysMeals {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return _meals.where((meal) =>
      meal.mealTime.isAfter(startOfDay) &&
      meal.mealTime.isBefore(endOfDay)
    ).toList();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  Future<void> fetchMealsForDog(String dogId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      _setLoading(true);
      _setError('');

      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('meals')
          .where('dogId', isEqualTo: dogId)
          .orderBy('mealTime', descending: true)
          .limit(50)
          .get();

      _meals = snapshot.docs.map((doc) => Meal.fromFirestore(doc)).toList();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to fetch meals: $e');
      _setLoading(false);
    }
  }

  Future<bool> addMeal(Meal meal) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      _setLoading(true);
      _setError('');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('meals')
          .add(meal.toFirestore());

      _meals.insert(0, meal);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add meal: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateMeal(Meal meal) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      _setLoading(true);
      _setError('');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('meals')
          .doc(meal.id)
          .update(meal.toFirestore());

      final index = _meals.indexWhere((m) => m.id == meal.id);
      if (index != -1) {
        _meals[index] = meal;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update meal: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteMeal(String mealId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      _setLoading(true);
      _setError('');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('meals')
          .doc(mealId)
          .delete();

      _meals.removeWhere((meal) => meal.id == mealId);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete meal: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<FoodProduct?> scanBarcode(String barcode) async {
    try {
      _setLoading(true);
      _setError('');

      final product = await _nutritionService.getProductByBarcode(barcode);
      _setLoading(false);
      return product;
    } catch (e) {
      _setError('Failed to scan barcode: $e');
      _setLoading(false);
      return null;
    }
  }

  List<Meal> getMealsForDate(String dogId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _meals.where((meal) =>
      meal.dogId == dogId &&
      meal.mealTime.isAfter(startOfDay) &&
      meal.mealTime.isBefore(endOfDay)
    ).toList();
  }

  double getTotalCaloriesForDate(String dogId, DateTime date) {
    final mealsForDate = getMealsForDate(dogId, date);
    return mealsForDate.fold(0.0, (total, meal) => total + meal.calories);
  }

  Map<DateTime, double> getWeeklyCalories(String dogId) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weeklyData = <DateTime, double>{};

    for (int i = 0; i < 7; i++) {
      final date = weekAgo.add(Duration(days: i));
      final dateKey = DateTime(date.year, date.month, date.day);
      weeklyData[dateKey] = getTotalCaloriesForDate(dogId, date);
    }

    return weeklyData;
  }
}
