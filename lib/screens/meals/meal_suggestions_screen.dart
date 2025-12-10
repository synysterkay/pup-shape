import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pupshape/config/theme.dart';
import 'package:pupshape/providers/dog_provider.dart';
import 'package:pupshape/providers/meal_provider.dart';
import 'package:pupshape/providers/plan_provider.dart';
import 'package:pupshape/services/meal_suggestions_service.dart';
import 'package:pupshape/services/test_data_generator.dart';

class MealSuggestionsScreen extends StatefulWidget {
  const MealSuggestionsScreen({super.key});

  @override
  State<MealSuggestionsScreen> createState() => _MealSuggestionsScreenState();
}

class _MealSuggestionsScreenState extends State<MealSuggestionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MealSuggestionsService _suggestionsService = MealSuggestionsService();
  
  List<MealSuggestion> _suggestions = [];
  ShoppingList? _shoppingList;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Don't auto-load suggestions, let user trigger it
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // TEST ONLY - Remove before production
  Future<void> _loadTestData() async {
    setState(() {
      _suggestions = TestDataGenerator.getMockMealSuggestions();
      _isLoading = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Test data loaded! Ready for screenshots'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadSuggestions() async {
    setState(() => _isLoading = true);

    final dogProvider = Provider.of<DogProvider>(context, listen: false);
    final mealProvider = Provider.of<MealProvider>(context, listen: false);
    final dog = dogProvider.selectedDog;

    if (dog == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _RecipeLoadingDialog(),
      );
    }

    try {
      // Get frequently logged meals
      final meals = mealProvider.meals;
      final mealNames = meals.map((m) => m.foodName).toSet().take(5).toList();

      final suggestions = await _suggestionsService.getRecipeVariations(
        dog: dog,
        frequentMeals: mealNames.isEmpty ? ['chicken and rice'] : mealNames,
      );

      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();
        
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading suggestions: $e');
      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();
        
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading suggestions: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Meal Suggestions',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Recipe Ideas'),
            Tab(text: 'Shopping List'),
            Tab(text: 'Portion Guide'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRecipeIdeasTab(),
          _buildShoppingListTab(),
          _buildPortionGuideTab(),
        ],
      ),
    );
  }

  Widget _buildRecipeIdeasTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_suggestions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Recipe Ideas Generator',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Get personalized recipe variations based on your dog\'s meal history and nutritional needs',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondaryColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.blue, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'AI-generated recipe variations',
                            style: TextStyle(fontSize: 14, color: Colors.blue[900]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.blue, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Nutritional information for each recipe',
                            style: TextStyle(fontSize: 14, color: Colors.blue[900]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.blue, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Portion guides tailored to your dog',
                            style: TextStyle(fontSize: 14, color: Colors.blue[900]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _loadSuggestions,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate Recipe Ideas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
              const SizedBox(height: 16),
              // TEST BUTTON - Remove before production
              OutlinedButton.icon(
                onPressed: _loadTestData,
                icon: const Icon(Icons.science),
                label: const Text('Generate Test Data (Screenshots)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSuggestions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return _buildRecipeCard(suggestion);
        },
      ),
    );
  }

  Widget _buildRecipeCard(MealSuggestion suggestion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.restaurant, color: Colors.orange, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        '${suggestion.calories} kcal • ${suggestion.proteinSource}',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              suggestion.description,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.straighten, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Portion: ${suggestion.portionGuide}',
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ingredients:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestion.ingredients.map((ingredient) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ingredient,
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShoppingListTab() {
    if (_shoppingList != null) {
      return RefreshIndicator(
        onRefresh: _generateShoppingList,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._shoppingList!.categories.map((category) => _buildCategorySection(category)),
              if (_shoppingList!.storageTips.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.tips_and_updates, color: Colors.blue),
                          SizedBox(width: 12),
                          Text(
                            'Storage Tips',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._shoppingList!.storageTips.map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• $tip',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.blue[800],
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Shopping List Generator',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Generate a shopping list based on your meal plan for the week',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _generateShoppingList,
            icon: const Icon(Icons.list_alt),
            label: const Text('Generate List'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(ShoppingCategory category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(_getCategoryIcon(category.name), color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: category.items.map((item) => _buildShoppingItem(item)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingItem(ShoppingItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.primaryColor, width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                if (item.notes != null)
                  Text(
                    item.notes!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            item.quantity,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('protein') || name.contains('meat')) return Icons.set_meal;
    if (name.contains('vegetable')) return Icons.eco;
    if (name.contains('grain') || name.contains('carb')) return Icons.grain;
    if (name.contains('supplement')) return Icons.medical_services;
    if (name.contains('treat')) return Icons.cookie;
    return Icons.shopping_basket;
  }

  Future<void> _generateShoppingList() async {
    final dogProvider = Provider.of<DogProvider>(context, listen: false);
    final planProvider = Provider.of<PlanProvider>(context, listen: false);
    
    if (dogProvider.selectedDog == null || !planProvider.hasPlan) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the assessment first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _ShoppingListLoadingDialog(),
      );
    }

    try {
      // Get next 7 days of meals from plan
      final now = DateTime.now();
      final nextWeekPlans = planProvider.currentPlan!.dailyPlans
          .where((plan) => plan.date.isAfter(now.subtract(const Duration(days: 1))) && 
                           plan.date.isBefore(now.add(const Duration(days: 8))))
          .toList();

      final plannedMeals = nextWeekPlans
          .expand((day) => day.meals)
          .map((meal) => {
                'name': meal.foodName,
                'ingredients': meal.ingredients,
              })
          .toList();

      final shoppingList = await _suggestionsService.generateShoppingList(
        plannedMeals: plannedMeals,
        days: 7,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        setState(() {
          _shoppingList = shoppingList;
        });
      }
    } catch (e) {
      print('Error generating shopping list: $e');
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating list: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPortionGuideTab() {
    return Consumer<DogProvider>(
      builder: (context, dogProvider, child) {
        final dog = dogProvider.selectedDog;
        if (dog == null) {
          return const Center(child: Text('No dog selected'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6366F1).withOpacity(0.15),
                      const Color(0xFF6366F1).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Calorie Target',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${dog.dailyCaloricNeeds.toInt()} kcal/day',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Visual Portion Guides',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildPortionGuideCard(
                'Dry Kibble',
                'About 1-1.5 cups',
                '🥣 Size of a tennis ball',
                '200-300g',
                Icons.grain,
                Colors.brown,
              ),
              _buildPortionGuideCard(
                'Wet Food',
                'About 400-500g',
                '🥘 Size of a fist',
                '1-1.5 cans',
                Icons.food_bank,
                Colors.orange,
              ),
              _buildPortionGuideCard(
                'Raw/Cooked Meat',
                'About 150-200g',
                '🍖 Size of your palm',
                'Protein-rich meal',
                Icons.set_meal,
                Colors.red,
              ),
              _buildPortionGuideCard(
                'Treats',
                'Max 10% of daily calories',
                '🦴 2-3 small treats',
                '${(dog.dailyCaloricNeeds * 0.1).toInt()} kcal',
                Icons.cookie,
                Colors.purple,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tips_and_updates, color: Colors.blue),
                        SizedBox(width: 12),
                        Text(
                          'Measuring Tips',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Use a kitchen scale for accuracy\n'
                      '• Measure food before adding water\n'
                      '• Split meals: 40% breakfast, 40% dinner, 20% treats\n'
                      '• Adjust portions based on weight progress',
                      style: TextStyle(fontSize: 13, height: 1.5, color: Colors.blue[800]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPortionGuideCard(
    String title,
    String amount,
    String visual,
    String extra,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  amount,
                  style: TextStyle(fontSize: 14, color: color),
                ),
                Text(
                  visual,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  extra,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Loading dialog for shopping list generation
class _ShoppingListLoadingDialog extends StatefulWidget {
  const _ShoppingListLoadingDialog();

  @override
  State<_ShoppingListLoadingDialog> createState() => _ShoppingListLoadingDialogState();
}

class _ShoppingListLoadingDialogState extends State<_ShoppingListLoadingDialog> with TickerProviderStateMixin {
  final List<String> _logs = [];
  int _currentLogIndex = 0;
  late AnimationController _dotsController;
  
  final List<String> _allLogs = [
    '📋 Analyzing your meal plan...',
    '🛒 Organizing ingredients by category...',
    '📊 Calculating quantities needed...',
    '💰 Estimating costs...',
    '✨ Adding storage tips...',
  ];

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _startLogging();
  }

  void _startLogging() async {
    for (int i = 0; i < _allLogs.length; i++) {
      if (!mounted) return;
      await Future.delayed(Duration(milliseconds: 400 + (i * 80)));
      if (!mounted) return;
      setState(() {
        _logs.add(_allLogs[i]);
        _currentLogIndex = i;
      });
    }
  }

  @override
  void dispose() {
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_cart,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Generating Shopping List',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _dotsController,
              builder: (context, child) {
                final dots = (_dotsController.value * 3).floor() % 4;
                return Text(
                  'Please wait${'.' * dots}${' ' * (3 - dots)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: (_currentLogIndex + 1) / _allLogs.length),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _logs.map((log) {
                    final index = _logs.indexOf(log);
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 300),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  index == _logs.length - 1
                                      ? Icons.hourglass_empty
                                      : Icons.check_circle,
                                  size: 16,
                                  color: index == _logs.length - 1
                                      ? const Color(0xFF6366F1)
                                      : Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    log,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: index == _logs.length - 1
                                          ? const Color(0xFF1E293B)
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Loading dialog for recipe generation
class _RecipeLoadingDialog extends StatefulWidget {
  const _RecipeLoadingDialog();

  @override
  State<_RecipeLoadingDialog> createState() => _RecipeLoadingDialogState();
}

class _RecipeLoadingDialogState extends State<_RecipeLoadingDialog> with TickerProviderStateMixin {
  final List<String> _logs = [];
  int _currentLogIndex = 0;
  late AnimationController _dotsController;
  
  final List<String> _allLogs = [
    '🔍 Analyzing your dog\'s meal history...',
    '🤖 Consulting AI...',
    '🍖 Generating recipe variations...',
    '📊 Calculating nutritional values...',
    '✨ Finalizing recommendations...',
  ];

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _startLogging();
  }

  void _startLogging() async {
    for (int i = 0; i < _allLogs.length; i++) {
      if (!mounted) return;
      await Future.delayed(Duration(milliseconds: 400 + (i * 80)));
      if (!mounted) return;
      setState(() {
        _logs.add(_allLogs[i]);
        _currentLogIndex = i;
      });
    }
  }

  @override
  void dispose() {
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.restaurant_menu,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Generating Recipe Ideas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Animated dots
            AnimatedBuilder(
              animation: _dotsController,
              builder: (context, child) {
                final dots = (_dotsController.value * 3).floor() % 4;
                return Text(
                  'Please wait${'.' * dots}${' ' * (3 - dots)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: (_currentLogIndex + 1) / _allLogs.length),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Log container
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _logs.map((log) {
                    final index = _logs.indexOf(log);
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 300),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  index == _logs.length - 1
                                      ? Icons.hourglass_empty
                                      : Icons.check_circle,
                                  size: 16,
                                  color: index == _logs.length - 1
                                      ? const Color(0xFF6366F1)
                                      : Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    log,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: index == _logs.length - 1
                                          ? const Color(0xFF1E293B)
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
