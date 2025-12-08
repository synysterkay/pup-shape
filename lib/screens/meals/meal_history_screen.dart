import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pupshape/providers/dog_provider.dart';
import 'package:pupshape/providers/meal_provider.dart';
import 'package:pupshape/screens/meals/meal_logging_screen.dart';
import 'package:intl/intl.dart';

class MealHistoryScreen extends StatefulWidget {
  const MealHistoryScreen({super.key});

  @override
  State<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: Consumer2<DogProvider, MealProvider>(
        builder: (context, dogProvider, mealProvider, child) {
          final selectedDog = dogProvider.selectedDog;
          if (selectedDog == null) {
            return const Center(
              child: Text('Please select a dog first'),
            );
          }

          final mealsForDate = mealProvider.meals
              .where((meal) => 
                  meal.dogId == selectedDog.id &&
                  _isSameDay(meal.mealTime, _selectedDate))
              .toList();

          mealsForDate.sort((a, b) => b.mealTime.compareTo(a.mealTime));

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Total: ${_getTotalCalories(mealsForDate).toInt()} kcal',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: mealsForDate.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No meals logged for this date',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: mealsForDate.length,
                        itemBuilder: (context, index) {
                          final meal = mealsForDate[index];
                          return _buildMealCard(meal);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MealLoggingScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMealCard(meal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MealLoggingScreen(meal: meal),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      meal.foodName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getMealTypeColor(meal.mealType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      meal.mealType.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getMealTypeColor(meal.mealType),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.scale, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${meal.quantity}g'),
                  const SizedBox(width: 16),
                  Icon(Icons.local_fire_department, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${meal.calories.toInt()} kcal'),
                  const Spacer(),
                  Text(
                    DateFormat('HH:mm').format(meal.mealTime),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              if (meal.notes != null && meal.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  meal.notes!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getMealTypeColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.blue;
      case 'snack':
        return Colors.purple;
      case 'treat':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  double _getTotalCalories(List meals) {
    return meals.fold(0.0, (sum, meal) => sum + meal.calories);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }
}
