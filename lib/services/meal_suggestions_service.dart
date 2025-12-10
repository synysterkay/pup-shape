import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:pupshape/models/dog.dart';

class MealSuggestionsService {
  static const String _apiKey = 'sk-ee74bd7f230a455a96936b267e0e1a7d';
  static const String _baseUrl = 'https://api.deepseek.com/v1/chat/completions';
  
  static void _checkWebPlatform() {
    if (kIsWeb) {
      throw Exception('AI meal suggestions require the mobile app. Basic meal logging works on web!');
    }
  }

  /// Get recipe variations based on frequently logged meals
  Future<List<MealSuggestion>> getRecipeVariations({
    required Dog dog,
    required List<String> frequentMeals,
  }) async {
    _checkWebPlatform();
    
    try {
      final prompt = '''
The dog owner frequently logs these meals: ${frequentMeals.join(', ')}

Generate 3 healthy variations/alternatives for variety:
- Same calorie range
- Different protein sources
- Breed-appropriate for ${dog.breed}
- Age-appropriate for ${dog.age} years old

Return JSON array:
[
  {
    "name": "<meal name>",
    "calories": <number>,
    "protein_source": "<source>",
    "description": "<brief description>",
    "portion_guide": "<visual portion guide>",
    "ingredients": ["<ingredient1>", "<ingredient2>"]
  }
]
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
              'content': 'You are a veterinary nutritionist providing meal suggestions for dogs.',
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.8,
          'max_tokens': 800,
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
        
        final List<dynamic> suggestions = jsonDecode(jsonContent);
        return suggestions.map((s) => MealSuggestion.fromJson(s)).toList();
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting recipe variations: $e');
      return _getFallbackSuggestions();
    }
  }

  /// Generate shopping list from meal plan
  Future<ShoppingList> generateShoppingList({
    required List<Map<String, dynamic>> plannedMeals,
    required int days,
  }) async {
    try {
      final mealsList = plannedMeals.map((m) => '${m['name']} (${m['ingredients'].join(', ')})').join('\n');
      
      final prompt = '''
Generate a shopping list for $days days of meals:

$mealsList

Group by category (Proteins, Vegetables, Grains, Supplements, Treats) and provide quantities.

Return JSON:
{
  "categories": [
    {
      "name": "<category>",
      "items": [
        {"name": "<item>", "quantity": "<amount>", "notes": "<optional>"}
      ]
    }
  ],
  "estimated_cost": "<range>",
  "storage_tips": ["<tip1>", "<tip2>"]
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
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
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
        
        return ShoppingList.fromJson(jsonDecode(jsonContent));
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error generating shopping list: $e');
      return ShoppingList.empty();
    }
  }

  /// Get portion calculator with visual guides
  Future<PortionGuide> getPortionGuide({
    required double targetCalories,
    required String foodType,
  }) async {
    try {
      final prompt = '''
Provide visual portion guidance for $foodType to reach $targetCalories calories:

Return JSON:
{
  "food_type": "$foodType",
  "target_calories": $targetCalories,
  "portions": [
    {
      "amount": "<weight in grams>",
      "visual_comparison": "<e.g., size of a tennis ball>",
      "calories": <number>,
      "meal_split": "<e.g., Breakfast: 40%, Dinner: 40%, Treats: 20%>"
    }
  ],
  "measuring_tips": ["<tip1>", "<tip2>"]
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
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.5,
          'max_tokens': 500,
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
        
        return PortionGuide.fromJson(jsonDecode(jsonContent));
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting portion guide: $e');
      return PortionGuide.empty();
    }
  }

  List<MealSuggestion> _getFallbackSuggestions() {
    return [
      MealSuggestion(
        name: 'Chicken & Sweet Potato',
        calories: 350,
        proteinSource: 'Chicken',
        description: 'Lean protein with complex carbs',
        portionGuide: 'About the size of your palm',
        ingredients: ['Chicken breast', 'Sweet potato', 'Fish oil'],
      ),
      MealSuggestion(
        name: 'Salmon & Brown Rice',
        calories: 340,
        proteinSource: 'Salmon',
        description: 'Omega-3 rich meal',
        portionGuide: 'Similar to a tennis ball',
        ingredients: ['Salmon fillet', 'Brown rice', 'Carrots'],
      ),
    ];
  }
}

class MealSuggestion {
  final String name;
  final int calories;
  final String proteinSource;
  final String description;
  final String portionGuide;
  final List<String> ingredients;

  MealSuggestion({
    required this.name,
    required this.calories,
    required this.proteinSource,
    required this.description,
    required this.portionGuide,
    required this.ingredients,
  });

  factory MealSuggestion.fromJson(Map<String, dynamic> json) {
    return MealSuggestion(
      name: json['name'] ?? '',
      calories: json['calories'] ?? 0,
      proteinSource: json['protein_source'] ?? '',
      description: json['description'] ?? '',
      portionGuide: json['portion_guide'] ?? '',
      ingredients: List<String>.from(json['ingredients'] ?? []),
    );
  }
}

class ShoppingList {
  final List<ShoppingCategory> categories;
  final String estimatedCost;
  final List<String> storageTips;

  ShoppingList({
    required this.categories,
    required this.estimatedCost,
    required this.storageTips,
  });

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      categories: (json['categories'] as List)
          .map((c) => ShoppingCategory.fromJson(c))
          .toList(),
      estimatedCost: json['estimated_cost'] ?? '',
      storageTips: List<String>.from(json['storage_tips'] ?? []),
    );
  }

  factory ShoppingList.empty() {
    return ShoppingList(
      categories: [],
      estimatedCost: 'N/A',
      storageTips: [],
    );
  }
}

class ShoppingCategory {
  final String name;
  final List<ShoppingItem> items;

  ShoppingCategory({
    required this.name,
    required this.items,
  });

  factory ShoppingCategory.fromJson(Map<String, dynamic> json) {
    return ShoppingCategory(
      name: json['name'] ?? '',
      items: (json['items'] as List)
          .map((i) => ShoppingItem.fromJson(i))
          .toList(),
    );
  }
}

class ShoppingItem {
  final String name;
  final String quantity;
  final String? notes;

  ShoppingItem({
    required this.name,
    required this.quantity,
    this.notes,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? '',
      notes: json['notes'],
    );
  }
}

class PortionGuide {
  final String foodType;
  final double targetCalories;
  final List<PortionInfo> portions;
  final List<String> measuringTips;

  PortionGuide({
    required this.foodType,
    required this.targetCalories,
    required this.portions,
    required this.measuringTips,
  });

  factory PortionGuide.fromJson(Map<String, dynamic> json) {
    return PortionGuide(
      foodType: json['food_type'] ?? '',
      targetCalories: (json['target_calories'] ?? 0).toDouble(),
      portions: (json['portions'] as List)
          .map((p) => PortionInfo.fromJson(p))
          .toList(),
      measuringTips: List<String>.from(json['measuring_tips'] ?? []),
    );
  }

  factory PortionGuide.empty() {
    return PortionGuide(
      foodType: '',
      targetCalories: 0,
      portions: [],
      measuringTips: [],
    );
  }
}

class PortionInfo {
  final String amount;
  final String visualComparison;
  final int calories;
  final String mealSplit;

  PortionInfo({
    required this.amount,
    required this.visualComparison,
    required this.calories,
    required this.mealSplit,
  });

  factory PortionInfo.fromJson(Map<String, dynamic> json) {
    return PortionInfo(
      amount: json['amount'] ?? '',
      visualComparison: json['visual_comparison'] ?? '',
      calories: json['calories'] ?? 0,
      mealSplit: json['meal_split'] ?? '',
    );
  }
}
