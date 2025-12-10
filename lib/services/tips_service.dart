import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pupshape/models/daily_tip.dart';
import 'package:pupshape/models/dog.dart';
import 'package:pupshape/models/weight_log.dart';

class TipsService {
  static const String _apiKey = 'sk-ee74bd7f230a455a96936b267e0e1a7d';
  static const String _baseUrl = 'https://api.deepseek.com/v1/chat/completions';
  
  static String get _apiUrl {
    if (kIsWeb) {
      return 'https://cors-anywhere.herokuapp.com/https://api.deepseek.com/v1/chat/completions';
    }
    return _baseUrl;
  }
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate a personalized daily tip for a dog
  Future<DailyTip> generateDailyTip({
    required Dog dog,
    List<WeightLog>? recentWeightLogs,
    int? currentStreak,
    int? weekNumber,
  }) async {
    
    try {
      // Calculate progress
      final startWeight = dog.weight;
      final targetWeight = dog.targetWeight ?? (startWeight * 0.85);
      final currentWeight = recentWeightLogs?.isNotEmpty == true 
          ? recentWeightLogs!.first.weight 
          : startWeight;
      
      final totalWeightToLose = startWeight - targetWeight;
      final weightLost = startWeight - currentWeight;
      final progressPercent = totalWeightToLose > 0 
          ? ((weightLost / totalWeightToLose) * 100).clamp(0, 100).toDouble()
          : 0.0;

      // Determine phase
      final phase = _determinePhase(weekNumber ?? 1, progressPercent);
      
      // Determine if plateau
      final isPlateauing = _checkPlateau(recentWeightLogs);

      final prompt = '''
Generate a motivational and educational daily tip for a dog owner with the following context:

Dog Profile:
- Name: ${dog.name}
- Breed: ${dog.breed}
- Age: ${dog.age} years
- Current Weight: ${currentWeight.toStringAsFixed(1)}kg
- Target Weight: ${targetWeight.toStringAsFixed(1)}kg
- Progress: ${progressPercent.toStringAsFixed(1)}% of goal
- Activity Level: ${dog.activityLevel}
- Current Streak: ${currentStreak ?? 0} days

Journey Phase: $phase
${isPlateauing ? 'NOTE: Weight appears to be plateauing' : ''}

Generate a JSON response:
{
  "title": "<Catchy, encouraging title>",
  "content": "<2-3 sentences with practical advice or motivation>",
  "category": "<motivation|nutrition|exercise|health|breed>",
  "iconEmoji": "<relevant emoji>"
}

Guidelines:
- Be specific to the dog's breed when relevant
- Reference their progress to keep them motivated
- Mix practical tips with encouragement
- If plateauing, suggest gentle adjustments
- Keep it positive and actionable
''';

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an encouraging dog health coach who provides bite-sized, practical daily tips.',
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.8,
          'max_tokens': 300,
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
        
        final tipData = jsonDecode(jsonContent);
        
        // Create and save the tip
        final tip = DailyTip(
          id: '', // Will be set by Firestore
          dogId: dog.id,
          title: tipData['title'] ?? 'Daily Tip',
          content: tipData['content'] ?? '',
          category: tipData['category'] ?? 'motivation',
          date: DateTime.now(),
          iconEmoji: tipData['iconEmoji'],
        );

        // Save to Firestore
        final docRef = await _firestore
            .collection('daily_tips')
            .add(tip.toFirestore());
        
        return tip.copyWith(id: docRef.id);
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error generating daily tip: $e');
      // Return a fallback tip
      return _getFallbackTip(dog);
    }
  }

  /// Get today's tip for a dog (from cache or generate new)
  Future<DailyTip?> getTodaysTip(String dogId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('daily_tips')
          .where('dogId', isEqualTo: dogId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return DailyTip.fromFirestore(snapshot.docs.first);
      }

      return null;
    } catch (e) {
      print('Error fetching today\'s tip: $e');
      return null;
    }
  }

  /// Get tip history for a dog
  Future<List<DailyTip>> getTipHistory(String dogId, {int limit = 30}) async {
    try {
      final snapshot = await _firestore
          .collection('daily_tips')
          .where('dogId', isEqualTo: dogId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => DailyTip.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching tip history: $e');
      return [];
    }
  }

  /// Mark a tip as read
  Future<void> markTipAsRead(String tipId) async {
    try {
      await _firestore
          .collection('daily_tips')
          .doc(tipId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking tip as read: $e');
    }
  }

  String _determinePhase(int weekNumber, double progressPercent) {
    if (weekNumber <= 2) {
      return 'Early Journey - Building Habits';
    } else if (weekNumber <= 4) {
      return 'Foundation Phase - Finding Rhythm';
    } else if (weekNumber <= 8) {
      return 'Mid-Journey - Staying Strong';
    } else if (weekNumber <= 10) {
      return 'Home Stretch - Almost There';
    } else {
      return 'Final Push - Finishing Strong';
    }
  }

  bool _checkPlateau(List<WeightLog>? logs) {
    if (logs == null || logs.length < 3) return false;
    
    // Check if last 3 weigh-ins show minimal change (< 0.2kg)
    final recent = logs.take(3).toList();
    final weights = recent.map((log) => log.weight).toList();
    final maxDiff = weights.reduce((a, b) => a > b ? a : b) - 
                    weights.reduce((a, b) => a < b ? a : b);
    
    return maxDiff < 0.2;
  }

  DailyTip _getFallbackTip(Dog dog) {
    final fallbackTips = [
      {
        'title': 'Stay Consistent!',
        'content': 'Small daily actions lead to big results. Keep logging ${dog.name}\'s meals!',
        'category': 'motivation',
        'icon': '💪',
      },
      {
        'title': 'Hydration Matters',
        'content': 'Make sure ${dog.name} has fresh water available at all times. Proper hydration supports healthy weight loss!',
        'category': 'health',
        'icon': '💧',
      },
      {
        'title': 'Walk Time!',
        'content': 'A 30-minute walk burns calories and strengthens the bond with ${dog.name}. Try exploring a new route today!',
        'category': 'exercise',
        'icon': '🚶',
      },
    ];

    final random = fallbackTips[DateTime.now().day % fallbackTips.length];
    
    return DailyTip(
      id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      dogId: dog.id,
      title: random['title']!,
      content: random['content']!,
      category: random['category']!,
      date: DateTime.now(),
      iconEmoji: random['icon'],
    );
  }
}
