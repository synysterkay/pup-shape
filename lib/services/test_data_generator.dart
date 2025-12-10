import 'package:pupshape/models/daily_tip.dart';
import 'package:pupshape/models/meal_plan.dart';
import 'package:pupshape/services/meal_suggestions_service.dart';

/// TEST ONLY - Remove before production
/// Generates mock AI content for screenshots without calling DeepSeek API
class TestDataGenerator {
  static List<MealSuggestion> getMockMealSuggestions() {
    return [
      MealSuggestion(
        name: 'Grilled Chicken & Quinoa Bowl',
        calories: 380,
        proteinSource: 'Chicken breast',
        description: 'Lean protein with ancient grains, packed with amino acids. Perfect for weight management while maintaining muscle mass.',
        portionGuide: '200g - About the size of a deck of cards',
        ingredients: [
          '150g grilled chicken breast',
          '50g cooked quinoa',
          '2 tbsp steamed broccoli',
          '1 tsp fish oil',
        ],
      ),
      MealSuggestion(
        name: 'Salmon & Sweet Potato Delight',
        calories: 375,
        proteinSource: 'Wild salmon',
        description: 'Omega-3 rich salmon promotes healthy skin and coat. Sweet potato provides sustained energy and fiber for digestion.',
        portionGuide: '180g - Size of a tennis ball',
        ingredients: [
          '120g baked salmon fillet',
          '40g mashed sweet potato',
          '20g green beans',
          'Pinch of turmeric',
        ],
      ),
      MealSuggestion(
        name: 'Turkey & Brown Rice Medley',
        calories: 370,
        proteinSource: 'Ground turkey',
        description: 'Low-fat turkey combined with whole grain brown rice. Gentle on sensitive stomachs while providing complete nutrition.',
        portionGuide: '195g - Size of a baseball',
        ingredients: [
          '140g lean ground turkey',
          '35g cooked brown rice',
          '15g diced carrots',
          '5g parsley',
        ],
      ),
      MealSuggestion(
        name: 'Beef & Pumpkin Power Bowl',
        calories: 390,
        proteinSource: 'Lean beef',
        description: 'Iron-rich beef supports energy levels. Pumpkin aids digestion and provides essential vitamins for immune health.',
        portionGuide: '205g - Slightly larger than a tennis ball',
        ingredients: [
          '130g extra lean ground beef',
          '50g pumpkin puree',
          '20g oatmeal',
          '5g spinach',
        ],
      ),
      MealSuggestion(
        name: 'Duck & Blueberry Feast',
        calories: 385,
        proteinSource: 'Duck breast',
        description: 'Novel protein perfect for dogs with allergies. Blueberries provide antioxidants for brain health and aging support.',
        portionGuide: '200g - Size of your fist',
        ingredients: [
          '145g duck breast',
          '30g cooked barley',
          '20g fresh blueberries',
          '5g flaxseed',
        ],
      ),
      MealSuggestion(
        name: 'Venison & Butternut Squash',
        calories: 395,
        proteinSource: 'Venison',
        description: 'Premium lean game meat for ultimate protein quality. Butternut squash delivers beta-carotene for eye and immune health.',
        portionGuide: '210g - Size of a large orange',
        ingredients: [
          '155g ground venison',
          '40g roasted butternut squash',
          '10g peas',
          '5g coconut oil',
        ],
      ),
    ];
  }

  static DailyTip getMockDailyTip({
    required String dogId,
    required String dogName,
  }) {
    final tips = [
      {
        'title': '💧 Hydration Check',
        'content': 'Great job, $dogName! Make sure fresh water is always available. During weight loss, dogs may drink more as their metabolism adjusts. Check the bowl 3-4 times daily.',
        'category': 'nutrition',
      },
      {
        'title': '🏃 Activity Boost',
        'content': 'Try adding 5 extra minutes to $dogName\'s walk today! Small increases in activity compound over time. Even gentle play sessions burn calories and strengthen your bond.',
        'category': 'exercise',
      },
      {
        'title': '⚖️ Progress Reminder',
        'content': 'You\'re on track! Healthy weight loss for $dogName is 1-2% of body weight per week. Slow and steady prevents muscle loss and keeps metabolism strong.',
        'category': 'health',
      },
      {
        'title': '🎯 Consistency Wins',
        'content': 'Stick to $dogName\'s meal schedule! Feeding at the same times daily regulates metabolism and reduces begging behaviors. Your routine is working!',
        'category': 'nutrition',
      },
      {
        'title': '👃 Sniff Walks',
        'content': 'Let $dogName sniff more on walks! Mental stimulation from sniffing tires dogs out as much as physical exercise. It\'s a workout for the brain!',
        'category': 'exercise',
      },
      {
        'title': '🥕 Smart Snacking',
        'content': 'Carrot sticks make perfect low-calorie treats for $dogName! Crunchy veggies satisfy chewing instincts while adding only 4 calories per baby carrot.',
        'category': 'nutrition',
      },
    ];

    final tip = tips[DateTime.now().day % tips.length];

    return DailyTip(
      id: 'test_tip_${DateTime.now().millisecondsSinceEpoch}',
      dogId: dogId,
      date: DateTime.now(),
      title: tip['title']!,
      content: tip['content']!,
      category: tip['category']!,
      phase: 'active',
      read: false,
    );
  }

  static WeightLossPlan getMockWeightLossPlan({
    required String dogId,
    required String dogName,
    required double currentWeight,
    required double targetWeight,
  }) {
    final startDate = DateTime.now();
    final endDate = startDate.add(const Duration(days: 84));
    
    // Create 7-day meal rotation (repeats weekly)
    final mealTemplates = [
      // Day 1
      [
        {'type': 'breakfast', 'name': 'Chicken & Rice Power Bowl', 'calories': 380, 'portion': '200g', 'ingredients': ['Chicken breast', 'Brown rice', 'Fish oil', 'Broccoli']},
        {'type': 'dinner', 'name': 'Salmon & Quinoa', 'calories': 380, 'portion': '185g', 'ingredients': ['Wild salmon', 'Quinoa', 'Carrots', 'Kelp']},
        {'type': 'treats', 'name': 'Veggie Crunch', 'calories': 190, 'portion': '100g', 'ingredients': ['Carrot sticks', 'Green beans', 'Dental chew']},
      ],
      // Day 2
      [
        {'type': 'breakfast', 'name': 'Turkey & Sweet Potato', 'calories': 370, 'portion': '195g', 'ingredients': ['Ground turkey', 'Sweet potato', 'Spinach', 'Flaxseed']},
        {'type': 'dinner', 'name': 'Beef & Pumpkin', 'calories': 390, 'portion': '200g', 'ingredients': ['Lean beef', 'Pumpkin puree', 'Oatmeal', 'Parsley']},
        {'type': 'treats', 'name': 'Apple Slices', 'calories': 190, 'portion': '80g', 'ingredients': ['Fresh apple slices', 'Small dental stick']},
      ],
      // Day 3
      [
        {'type': 'breakfast', 'name': 'Duck & Blueberry Bowl', 'calories': 385, 'portion': '200g', 'ingredients': ['Duck breast', 'Barley', 'Blueberries', 'Coconut oil']},
        {'type': 'dinner', 'name': 'Venison & Butternut Squash', 'calories': 375, 'portion': '190g', 'ingredients': ['Ground venison', 'Butternut squash', 'Peas']},
        {'type': 'treats', 'name': 'Frozen Banana', 'calories': 190, 'portion': '1/2 banana', 'ingredients': ['Frozen banana slices', 'Peanut butter (xylitol-free)']},
      ],
      // Day 4
      [
        {'type': 'breakfast', 'name': 'Lamb & Pearl Barley', 'calories': 390, 'portion': '205g', 'ingredients': ['Ground lamb', 'Pearl barley', 'Zucchini', 'Mint']},
        {'type': 'dinner', 'name': 'White Fish & Potato', 'calories': 370, 'portion': '195g', 'ingredients': ['Cod fillet', 'White potato', 'Green beans']},
        {'type': 'treats', 'name': 'Pumpkin Bites', 'calories': 190, 'portion': '50g', 'ingredients': ['Frozen pumpkin puree cubes', 'Small treat']},
      ],
      // Day 5
      [
        {'type': 'breakfast', 'name': 'Pork & Apple Medley', 'calories': 380, 'portion': '200g', 'ingredients': ['Pork loin', 'Apple chunks', 'Brown rice', 'Sage']},
        {'type': 'dinner', 'name': 'Chicken & Lentils', 'calories': 375, 'portion': '195g', 'ingredients': ['Chicken thigh', 'Red lentils', 'Carrots', 'Turmeric']},
        {'type': 'treats', 'name': 'Cucumber Slices', 'calories': 195, 'portion': '120g', 'ingredients': ['Cucumber rounds', 'Small dental chew']},
      ],
      // Day 6
      [
        {'type': 'breakfast', 'name': 'Bison & Cranberry', 'calories': 395, 'portion': '210g', 'ingredients': ['Ground bison', 'Quinoa', 'Cranberries', 'Rosemary']},
        {'type': 'dinner', 'name': 'Salmon & Chickpeas', 'calories': 365, 'portion': '185g', 'ingredients': ['Salmon', 'Chickpeas', 'Broccoli', 'Dill']},
        {'type': 'treats', 'name': 'Sweet Potato Chews', 'calories': 190, 'portion': '60g', 'ingredients': ['Dehydrated sweet potato strips']},
      ],
      // Day 7
      [
        {'type': 'breakfast', 'name': 'Turkey & Kale Bowl', 'calories': 375, 'portion': '200g', 'ingredients': ['Ground turkey', 'Kale', 'Brown rice', 'Chia seeds']},
        {'type': 'dinner', 'name': 'Beef & Cauliflower', 'calories': 385, 'portion': '200g', 'ingredients': ['Lean beef', 'Cauliflower', 'Sweet potato', 'Basil']},
        {'type': 'treats', 'name': 'Blueberry Frozen Treats', 'calories': 190, 'portion': '50g', 'ingredients': ['Frozen blueberries', 'Plain yogurt drops']},
      ],
    ];

    final dailyPlans = <DailyMealPlan>[];
    for (int day = 0; day < 84; day++) {
      final date = startDate.add(Duration(days: day));
      final dayOfWeek = day % 7;
      final meals = mealTemplates[dayOfWeek];
      
      dailyPlans.add(DailyMealPlan(
        date: date,
        dayNumber: day + 1,
        targetCalories: 950,
        notes: day % 7 == 0 ? 'Week ${(day ~/ 7) + 1} - You\'re doing amazing! Stay consistent.' : null,
        meals: meals.map((m) => PlannedMeal(
          id: '${m['type']}_$day',
          mealType: m['type'] as String,
          foodName: m['name'] as String,
          calories: m['calories'] as int,
          portion: m['portion'] as String,
          ingredients: List<String>.from(m['ingredients'] as List),
        )).toList(),
      ));
    }

    return WeightLossPlan(
      id: 'test_plan_${DateTime.now().millisecondsSinceEpoch}',
      dogId: dogId,
      startDate: startDate,
      endDate: endDate,
      startWeight: currentWeight,
      targetWeight: targetWeight,
      durationWeeks: 12,
      dailyCalories: 950,
      macros: {
        'protein': '28%',
        'fat': '12%',
        'carbs': '45%',
        'fiber': '5%',
      },
      dailyPlans: dailyPlans,
      createdAt: DateTime.now(),
    );
  }
}
