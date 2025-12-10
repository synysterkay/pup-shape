import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:pupshape/models/dog.dart';
import 'package:pupshape/models/meal_plan.dart';

class DeepSeekService {
  static const String _apiKey = 'sk-ee74bd7f230a455a96936b267e0e1a7d';
  static const String _baseUrl = 'https://api.deepseek.com/v1/chat/completions';
  
  static void _checkWebPlatform() {
    if (kIsWeb) {
      throw Exception(
        'AI Features Coming Soon on Web!\n\n'
        'Our AI nutritionist requires direct API access which isn\'t available in web browsers due to security restrictions.\n\n'
        '📱 Download the PupShape mobile app for full AI features:\n'
        '   • Personalized meal plans\n'
        '   • AI nutrition advice\n'
        '   • Daily health tips\n\n'
        'Basic features (meal logging, weight tracking) work on web!'
      );
    }
  }

  /// Generate a personalized weight management plan for a dog
  Future<DogNutritionPlan> generateWeightPlan({
    required String breed,
    required double currentWeight,
    required double targetWeight,
    required int ageYears,
    required String activityLevel,
    required String gender,
  }) async {
    _checkWebPlatform();
    
    try {
      final prompt = '''
Act as a veterinary nutritionist. Create a detailed weight management plan for a dog with the following profile:

Breed: $breed
Current Weight: $currentWeight kg
Target Weight: $targetWeight kg
Age: $ageYears years
Gender: $gender
Activity Level: $activityLevel

Provide a JSON response with the following structure:
{
  "daily_calories": <number>,
  "protein_grams": <number>,
  "fat_grams": <number>,
  "carbs_grams": <number>,
  "estimated_weeks_to_goal": <number>,
  "weight_loss_rate_per_week": <number in kg>,
  "feeding_schedule": "<recommendation>",
  "exercise_recommendation": "<specific activities>",
  "health_notes": "<breed-specific considerations>"
}

Important: Calculate safe weight loss (0.5-2% of body weight per week). Consider breed-specific metabolism and health concerns.
''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a certified veterinary nutritionist with 20 years of experience in canine weight management. Provide scientifically accurate, safe recommendations.',
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        // Extract JSON from markdown code blocks if present
        String jsonContent = content;
        if (content.contains('```json')) {
          jsonContent = content.split('```json')[1].split('```')[0].trim();
        } else if (content.contains('```')) {
          jsonContent = content.split('```')[1].split('```')[0].trim();
        }
        
        final planData = jsonDecode(jsonContent);
        return DogNutritionPlan.fromJson(planData);
      } else {
        throw Exception('DeepSeek API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to generate weight plan: $e');
    }
  }

  /// Get meal recommendations based on calorie target
  Future<String> getMealRecommendations({
    required double dailyCalories,
    required String breed,
    required List<String> allergies,
  }) async {
    try {
      final prompt = '''
Recommend 2-3 high-quality commercial dog food brands suitable for:
- Daily Caloric Need: $dailyCalories kcal
- Breed: $breed
- Allergies/Restrictions: ${allergies.isEmpty ? 'None' : allergies.join(', ')}

Provide specific brands, protein sources, and portion sizes in a concise format.
''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.8,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get meal recommendations: $e');
    }
  }

  /// Analyze food ingredient quality
  Future<FoodAnalysis> analyzeIngredients(String ingredientList) async {
    try {
      final prompt = '''
Analyze these dog food ingredients and provide a quality score:

Ingredients: $ingredientList

Provide JSON response:
{
  "quality_score": <0-100>,
  "grade": "<A-F>",
  "highlights": ["<positive aspects>"],
  "concerns": ["<negative aspects>"],
  "recommendation": "<brief summary>"
}
''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a pet food quality expert. Evaluate ingredients based on nutritional value, digestibility, and safety.',
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.5,
          'max_tokens': 600,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        String jsonContent = content;
        if (content.contains('```json')) {
          jsonContent = content.split('```json')[1].split('```')[0].trim();
        } else if (content.contains('```')) {
          jsonContent = content.split('```')[1].split('```')[0].trim();
        }
        
        final analysisData = jsonDecode(jsonContent);
        return FoodAnalysis.fromJson(analysisData);
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to analyze ingredients: $e');
    }
  }

  /// Generate a complete 12-week meal plan
  Future<WeightLossPlan> generateMealPlan(Dog dog) async {
    final targetWeight = dog.targetWeight ?? (dog.weight * 0.85);
    
    final prompt = '''
Generate a 12-week weight loss meal plan for:
- Breed: ${dog.breed}
- Age: ${dog.age} years
- Current: ${dog.weight}kg → Target: ${targetWeight.toStringAsFixed(1)}kg
- Activity: ${dog.activityLevel}

Create 7 unique daily meal plans (repeat weekly) with:
- Breakfast (40% calories)
- Dinner (40% calories)  
- Treats (20% calories)

JSON format:
{
  "dailyCalories": 950,
  "meals": [
    {"type": "breakfast", "name": "Chicken & Rice", "calories": 380, "portion": "200g", "ingredients": ["Chicken", "Rice", "Fish oil"]},
    {"type": "dinner", "name": "Salmon & Potato", "calories": 380, "portion": "180g", "ingredients": ["Salmon", "Sweet potato"]},
    {"type": "treats", "name": "Carrots", "calories": 190, "portion": "100g", "ingredients": ["Carrots", "Dental chew"]}
  ]
}
''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_apiKey'},
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [{'role': 'user', 'content': prompt}],
          'temperature': 0.7,
          'max_tokens': 2000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
        
        if (jsonMatch != null) {
          final planData = jsonDecode(jsonMatch.group(0)!);
          return _buildPlan(planData, dog, targetWeight);
        }
      }
      throw Exception('Failed to generate meal plan');
    } catch (e) {
      throw Exception('Meal plan generation error: $e');
    }
  }

  WeightLossPlan _buildPlan(Map<String, dynamic> planData, Dog dog, double targetWeight) {
    final startDate = DateTime.now();
    final dailyPlans = <DailyMealPlan>[];
    
    for (int day = 0; day < 84; day++) {
      final weekDay = day % 7;
      final meals = (planData['meals'] as List).map((m) {
        return PlannedMeal(
          id: '${m['type']}_$day',
          mealType: m['type'],
          foodName: m['name'],
          calories: m['calories'],
          portion: m['portion'],
          ingredients: List<String>.from(m['ingredients']),
        );
      }).toList();
      
      dailyPlans.add(DailyMealPlan(
        date: startDate.add(Duration(days: day)),
        dayNumber: day + 1,
        targetCalories: planData['dailyCalories'],
        meals: meals,
        notes: day % 7 == 0 ? 'Week ${(day ~/ 7) + 1} - Stay consistent!' : null,
      ));
    }

    return WeightLossPlan(
      id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
      dogId: dog.id,
      startDate: startDate,
      endDate: startDate.add(const Duration(days: 84)),
      startWeight: dog.weight,
      targetWeight: targetWeight,
      durationWeeks: 12,
      dailyCalories: planData['dailyCalories'],
      macros: {'protein': '28%', 'fat': '14%', 'carbs': '42%'},
      dailyPlans: dailyPlans,
      createdAt: DateTime.now(),
    );
  }
}

/// Model for nutrition plan response
class DogNutritionPlan {
  final int dailyCalories;
  final double proteinGrams;
  final double fatGrams;
  final double carbsGrams;
  final int estimatedWeeksToGoal;
  final double weightLossRatePerWeek;
  final String feedingSchedule;
  final String exerciseRecommendation;
  final String healthNotes;

  DogNutritionPlan({
    required this.dailyCalories,
    required this.proteinGrams,
    required this.fatGrams,
    required this.carbsGrams,
    required this.estimatedWeeksToGoal,
    required this.weightLossRatePerWeek,
    required this.feedingSchedule,
    required this.exerciseRecommendation,
    required this.healthNotes,
  });

  factory DogNutritionPlan.fromJson(Map<String, dynamic> json) {
    return DogNutritionPlan(
      dailyCalories: (json['daily_calories'] ?? 0).toInt(),
      proteinGrams: (json['protein_grams'] ?? 0).toDouble(),
      fatGrams: (json['fat_grams'] ?? 0).toDouble(),
      carbsGrams: (json['carbs_grams'] ?? 0).toDouble(),
      estimatedWeeksToGoal: (json['estimated_weeks_to_goal'] ?? 0).toInt(),
      weightLossRatePerWeek: (json['weight_loss_rate_per_week'] ?? 0).toDouble(),
      feedingSchedule: json['feeding_schedule'] ?? '',
      exerciseRecommendation: json['exercise_recommendation'] ?? '',
      healthNotes: json['health_notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daily_calories': dailyCalories,
      'protein_grams': proteinGrams,
      'fat_grams': fatGrams,
      'carbs_grams': carbsGrams,
      'estimated_weeks_to_goal': estimatedWeeksToGoal,
      'weight_loss_rate_per_week': weightLossRatePerWeek,
      'feeding_schedule': feedingSchedule,
      'exercise_recommendation': exerciseRecommendation,
      'health_notes': healthNotes,
    };
  }
}

/// Model for food analysis
class FoodAnalysis {
  final int qualityScore;
  final String grade;
  final List<String> highlights;
  final List<String> concerns;
  final String recommendation;

  FoodAnalysis({
    required this.qualityScore,
    required this.grade,
    required this.highlights,
    required this.concerns,
    required this.recommendation,
  });

  factory FoodAnalysis.fromJson(Map<String, dynamic> json) {
    return FoodAnalysis(
      qualityScore: json['quality_score'] ?? 0,
      grade: json['grade'] ?? 'N/A',
      highlights: List<String>.from(json['highlights'] ?? []),
      concerns: List<String>.from(json['concerns'] ?? []),
      recommendation: json['recommendation'] ?? '',
    );
  }
}
