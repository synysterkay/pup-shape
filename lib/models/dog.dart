import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Dog {
  final String id;
  final String name;
  final String breed;
  final int age; // in months
  final double weight; // in kg
  final double targetWeight; // in kg - goal weight
  final String activityLevel; // 'low', 'moderate', 'high'
  final String gender; // 'male', 'female'
  final bool isNeutered;
  final List<String> allergies;
  final List<String> healthConditions;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Feeding schedule properties
  final Map<String, Map<String, int>> mealSchedule; // {'breakfast': {'hour': 8, 'minute': 0}}
  final int mealsPerDay;
  final bool enableMealReminders;
  final int reminderMinutesBefore;

  Dog({
    required this.id,
    required this.name,
    required this.breed,
    required this.age,
    required this.weight,
    required this.targetWeight,
    required this.activityLevel,
    required this.gender,
    required this.isNeutered,
    required this.allergies,
    required this.healthConditions,
    required this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.mealSchedule,
    required this.mealsPerDay,
    required this.enableMealReminders,
    required this.reminderMinutesBefore,
  });

  // Calculate daily caloric needs based on dog's characteristics
  double get dailyCaloricNeeds {
    // Basic formula: RER (Resting Energy Requirement) * Activity Factor
    // RER = 70 * (weight in kg)^0.75
    double rer = 70 * (weight * 0.75);
    
    // Activity factor
    double activityFactor;
    switch (activityLevel) {
      case 'low':
        activityFactor = isNeutered ? 1.6 : 1.8;
        break;
      case 'moderate':
        activityFactor = isNeutered ? 1.8 : 2.0;
        break;
      case 'high':
        activityFactor = isNeutered ? 2.0 : 2.5;
        break;
      default:
        activityFactor = 1.8;
    }
    
    // Age factor (puppies need more calories)
    double ageFactor = age < 12 ? 2.0 : 1.0; // Under 1 year
    
    return rer * activityFactor * ageFactor;
  }

  // Get next meal type and time
  String? getNextMeal() {
    final now = DateTime.now();
    final currentTime = TimeOfDay.now();
    
    // Sort meals by time
    final sortedMeals = mealSchedule.entries.toList()
      ..sort((a, b) {
        final aTime = TimeOfDay(hour: a.value['hour']!, minute: a.value['minute']!);
        final bTime = TimeOfDay(hour: b.value['hour']!, minute: b.value['minute']!);
        return _timeOfDayToMinutes(aTime).compareTo(_timeOfDayToMinutes(bTime));
      });
    
    // Find next meal
    for (final meal in sortedMeals) {
      final mealTime = TimeOfDay(hour: meal.value['hour']!, minute: meal.value['minute']!);
      if (_timeOfDayToMinutes(mealTime) > _timeOfDayToMinutes(currentTime)) {
        return meal.key;
      }
    }
    
    // If no meal found today, return first meal of tomorrow
    return sortedMeals.isNotEmpty ? sortedMeals.first.key : null;
  }
  
  // Get meal time for a specific meal type
  TimeOfDay? getMealTime(String mealType) {
    final schedule = mealSchedule[mealType];
    if (schedule != null) {
      return TimeOfDay(hour: schedule['hour']!, minute: schedule['minute']!);
    }
    return null;
  }
  
  int _timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  // Create a copy with updated fields
  Dog copyWith({
    String? id,
    String? name,
    String? breed,
    int? age,
    double? weight,
    double? targetWeight,
    String? activityLevel,
    String? gender,
    bool? isNeutered,
    List<String>? allergies,
    List<String>? healthConditions,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, Map<String, int>>? mealSchedule,
    int? mealsPerDay,
    bool? enableMealReminders,
    int? reminderMinutesBefore,
  }) {
    return Dog(
      id: id ?? this.id,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      targetWeight: targetWeight ?? this.targetWeight,
      activityLevel: activityLevel ?? this.activityLevel,
      gender: gender ?? this.gender,
      isNeutered: isNeutered ?? this.isNeutered,
      allergies: allergies ?? this.allergies,
      healthConditions: healthConditions ?? this.healthConditions,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mealSchedule: mealSchedule ?? this.mealSchedule,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      enableMealReminders: enableMealReminders ?? this.enableMealReminders,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'breed': breed,
      'age': age,
      'weight': weight,
      'targetWeight': targetWeight,
      'activityLevel': activityLevel,
      'gender': gender,
      'isNeutered': isNeutered,
      'allergies': allergies,
      'healthConditions': healthConditions,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'mealSchedule': mealSchedule,
      'mealsPerDay': mealsPerDay,
      'enableMealReminders': enableMealReminders,
      'reminderMinutesBefore': reminderMinutesBefore,
    };
  }

  // Create from Firestore document
  factory Dog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Dog(
      id: doc.id,
      name: data['name'] ?? '',
      breed: data['breed'] ?? '',
      age: data['age'] ?? 12,
      weight: (data['weight'] ?? 10.0).toDouble(),
      targetWeight: (data['targetWeight'] ?? 10.0).toDouble(),
      activityLevel: data['activityLevel'] ?? 'moderate',
      gender: data['gender'] ?? 'male',
      isNeutered: data['isNeutered'] ?? false,
      allergies: List<String>.from(data['allergies'] ?? []),
      healthConditions: List<String>.from(data['healthConditions'] ?? []),
      imageUrl: data['imageUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mealSchedule: Map<String, Map<String, int>>.from(
        (data['mealSchedule'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, Map<String, int>.from(value)),
        ) ?? {
          'breakfast': {'hour': 8, 'minute': 0},
          'dinner': {'hour': 18, 'minute': 0},
        },
      ),
      mealsPerDay: data['mealsPerDay'] ?? 2,
      enableMealReminders: data['enableMealReminders'] ?? true,
      reminderMinutesBefore: data['reminderMinutesBefore'] ?? 30,
    );
  }

  @override
  String toString() {
    return 'Dog(id: $id, name: $name, breed: $breed, age: $age months, weight: ${weight}kg)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Dog && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
