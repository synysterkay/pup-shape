import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pupshape/config/theme.dart';
import 'package:pupshape/models/meal.dart';
import 'package:pupshape/providers/dog_provider.dart';
import 'package:pupshape/providers/meal_provider.dart';
import 'package:pupshape/providers/auth_provider.dart';
import 'package:pupshape/widgets/home/calorie_ring_widget.dart';
import 'package:pupshape/widgets/home/weight_progress_chart.dart';
import 'package:pupshape/widgets/home/quick_action_button.dart';
import 'package:pupshape/widgets/daily_tip_card.dart';
import 'dart:math' as math;

class NewHomeScreen extends StatefulWidget {
  const NewHomeScreen({super.key});

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final dogProvider = Provider.of<DogProvider>(context, listen: false);
    await dogProvider.fetchDogs();
    
    if (dogProvider.selectedDog != null) {
      final mealProvider = Provider.of<MealProvider>(context, listen: false);
      await mealProvider.fetchMealsForDog(dogProvider.selectedDog!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: Consumer2<DogProvider, MealProvider>(
            builder: (context, dogProvider, mealProvider, child) {
              final dog = dogProvider.selectedDog;
              
              if (dog == null) {
                return _buildNoDogState();
              }

              final todaysMeals = mealProvider.todaysMeals;
              final caloriesConsumed = todaysMeals.fold<double>(
                0.0,
                (sum, meal) => sum + meal.calories,
              );
              final caloriesRemaining = (dog.dailyCaloricNeeds - caloriesConsumed).clamp(0.0, dog.dailyCaloricNeeds);
              final progress = dog.dailyCaloricNeeds > 0 ? caloriesConsumed / dog.dailyCaloricNeeds : 0.0;

              return RefreshIndicator(
                onRefresh: _loadData,
                color: AppTheme.primaryColor,
                child: CustomScrollView(
                  slivers: [
                    // App Bar
                    _buildAppBar(context, dog.name),
                    
                    // Content
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Calorie Ring (Hero Section)
                            FadeTransition(
                              opacity: _animationController,
                              child: CalorieRingWidget(
                                caloriesConsumed: caloriesConsumed,
                                caloriesTarget: dog.dailyCaloricNeeds,
                                caloriesRemaining: caloriesRemaining,
                                progress: progress,
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Daily Tip
                            const DailyTipCard(),
                            
                            const SizedBox(height: 32),
                            
                            // Quick Actions
                            const Text(
                              'Quick Actions',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildQuickActions(context),
                            
                            const SizedBox(height: 32),
                            
                            // Weight Progress
                            const Text(
                              'Weight Progress',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            WeightProgressChart(
                              currentWeight: dog.weight,
                              targetWeight: dog.targetWeight,
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Today's Meals
                            _buildTodaysMeals(todaysMeals),
                            
                            const SizedBox(height: 100), // Bottom padding
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLogMealBottomSheet(context),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Log Meal',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String dogName) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          dogName,
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppTheme.textPrimaryColor),
          onPressed: () {
            // TODO: Notifications
          },
        ),
        IconButton(
          icon: const Icon(Icons.account_circle_outlined, color: AppTheme.textPrimaryColor),
          onPressed: () => _showProfileMenu(context),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: QuickActionButton(
                icon: Icons.restaurant,
                label: 'Breakfast',
                color: AppTheme.accentColor,
                onTap: () => _logMeal(context, 'breakfast'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionButton(
                icon: Icons.dinner_dining,
                label: 'Dinner',
                color: AppTheme.primaryColor,
                onTap: () => _logMeal(context, 'dinner'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionButton(
                icon: Icons.cookie,
                label: 'Treat',
                color: Colors.purple,
                onTap: () => _logMeal(context, 'treat'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: QuickActionButton(
                icon: Icons.show_chart,
                label: 'Progress',
                color: Colors.green,
                onTap: () {
                  Navigator.pushNamed(context, '/progress');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionButton(
                icon: Icons.calendar_today,
                label: 'Plan',
                color: Colors.blue,
                onTap: () {
                  Navigator.pushNamed(context, '/calendar');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionButton(
                icon: Icons.restaurant_menu,
                label: 'Recipes',
                color: Colors.orange,
                onTap: () {
                  Navigator.pushNamed(context, '/meal-suggestions');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodaysMeals(List meals) {
    if (meals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.fastfood_outlined,
              size: 48,
              color: AppTheme.textSecondaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No meals logged today',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the button below to log a meal',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today\'s Meals',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        ...meals.map((meal) => _buildMealCard(meal)).toList(),
      ],
    );
  }

  Widget _buildMealCard(dynamic meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.restaurant, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.foodName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meal.mealType,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${meal.calories}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const Text(
                'kcal',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoDogState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.pets,
              size: 80,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'No Dogs Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Add your first dog to get started with PupShape',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/assessment');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Add Dog',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logMeal(BuildContext context, String mealType) {
    _showLogMealBottomSheet(context, mealType: mealType);
  }

  void _showLogMealBottomSheet(BuildContext context, {String? mealType}) {
    final TextEditingController foodNameController = TextEditingController();
    final TextEditingController caloriesController = TextEditingController();
    final TextEditingController portionController = TextEditingController(text: '100');
    String selectedMealType = mealType ?? 'breakfast';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Log Meal',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Meal Type Selector
                DropdownButtonFormField<String>(
                  value: selectedMealType,
                  decoration: InputDecoration(
                    labelText: 'Meal Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ['breakfast', 'lunch', 'dinner', 'snack', 'treat']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.substring(0, 1).toUpperCase() + type.substring(1)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setModalState(() => selectedMealType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: foodNameController,
                  decoration: InputDecoration(
                    labelText: 'Food Name',
                    prefixIcon: const Icon(Icons.restaurant),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: caloriesController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Calories',
                          prefixIcon: const Icon(Icons.local_fire_department),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: portionController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Portion (g)',
                          prefixIcon: const Icon(Icons.scale),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                ElevatedButton(
                  onPressed: () async {
                    if (foodNameController.text.isNotEmpty &&
                        caloriesController.text.isNotEmpty) {
                      final dogProvider = Provider.of<DogProvider>(context, listen: false);
                      final mealProvider = Provider.of<MealProvider>(context, listen: false);
                      
                      if (dogProvider.selectedDog == null) return;
                      
                      final meal = Meal(
                        id: '',
                        dogId: dogProvider.selectedDog!.id,
                        foodName: foodNameController.text.trim(),
                        brand: '',
                        portionSize: double.tryParse(portionController.text) ?? 100.0,
                        calories: double.tryParse(caloriesController.text) ?? 0.0,
                        mealType: selectedMealType,
                        mealTime: DateTime.now(),
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );
                      
                      final success = await mealProvider.addMeal(meal);
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success 
                              ? 'Meal logged successfully!' 
                              : 'Failed to log meal'),
                            backgroundColor: success 
                              ? AppTheme.successColor 
                              : AppTheme.errorColor,
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all fields'),
                          backgroundColor: AppTheme.warningColor,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Log Meal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.account_circle, color: AppTheme.primaryColor),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed('/profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: AppTheme.primaryColor),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed('/settings');
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  await authProvider.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/auth');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
