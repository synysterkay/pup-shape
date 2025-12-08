import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pupshape/providers/dog_provider.dart';
import 'package:pupshape/providers/meal_provider.dart';
import 'package:pupshape/models/meal.dart';
import 'package:pupshape/models/dog.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class HealthInsightsScreen extends StatefulWidget {
  const HealthInsightsScreen({super.key});

  @override
  State<HealthInsightsScreen> createState() => _HealthInsightsScreenState();
}

class _HealthInsightsScreenState extends State<HealthInsightsScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Insights'),
      ),
      body: Consumer2<DogProvider, MealProvider>(
        builder: (context, dogProvider, mealProvider, child) {
          final selectedDog = dogProvider.selectedDog;
          if (selectedDog == null) {
            return const Center(
              child: Text('Please select a dog first'),
            );
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        selectedDog.name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedDog.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${selectedDog.breed} • ${selectedDog.weight}kg',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton('Overview', 0),
                    ),
                    Expanded(
                      child: _buildTabButton('Trends', 1),
                    ),
                    Expanded(
                      child: _buildTabButton('Recommendations', 2),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _selectedTabIndex,
                  children: [
                    _buildOverviewTab(selectedDog, mealProvider),
                    _buildTrendsTab(selectedDog, mealProvider),
                    _buildRecommendationsTab(selectedDog, mealProvider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(Dog selectedDog, MealProvider mealProvider) {
    final today = DateTime.now();
    final todayCalories = mealProvider.getTotalCaloriesForDate(selectedDog.id, today);
    final targetCalories = selectedDog.dailyCaloricNeeds;
    final weeklyAverage = _getWeeklyAverageCalories(selectedDog.id, mealProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricCard(
            'Daily Calorie Target',
            '${targetCalories.toInt()} kcal',
            Icons.local_fire_department,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildMetricCard(
            'Today\'s Intake',
            '${todayCalories.toInt()} kcal',
            Icons.restaurant,
            todayCalories > targetCalories ? Colors.red : Colors.green,
          ),
          const SizedBox(height: 12),
          _buildMetricCard(
            'Weekly Average',
            '${weeklyAverage.toInt()} kcal/day',
            Icons.trending_up,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildMetricCard(
            'Current Weight',
            '${selectedDog.weight.toStringAsFixed(1)} kg',
            Icons.monitor_weight,
            Colors.purple,
          ),
          const SizedBox(height: 20),
          const Text(
            'Calorie Progress Today',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildCalorieProgressChart(todayCalories, targetCalories),
          const SizedBox(height: 20),
          const Text(
            'Health Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildHealthStatusCard(selectedDog, todayCalories, targetCalories),
        ],
      ),
    );
  }

  Widget _buildTrendsTab(Dog selectedDog, MealProvider mealProvider) {
    final last7Days = _getLast7DaysData(selectedDog.id, mealProvider);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calorie Intake Trend (Last 7 Days)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final date = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                        return Text(
                          DateFormat('MM/dd').format(date),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: last7Days.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value);
                    }).toList(),
                    isCurved: true,
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: List.generate(7, (index) {
                      return FlSpot(index.toDouble(), selectedDog.dailyCaloricNeeds);
                    }),
                    isCurved: false,
                    color: Colors.red,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    dashArray: [5, 5],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildLegendItem('Actual Intake', Theme.of(context).colorScheme.primary),
              const SizedBox(width: 20),
              _buildLegendItem('Target', Colors.red),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Weekly Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildWeeklySummaryCard(last7Days, selectedDog.dailyCaloricNeeds),
        ],
      ),
    );
  }

  Widget _buildRecommendationsTab(Dog selectedDog, MealProvider mealProvider) {
    final recommendations = _generateRecommendations(selectedDog, mealProvider);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personalized Recommendations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...recommendations.map((rec) => _buildRecommendationCard(rec)),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
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
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieProgressChart(double current, double target) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 120,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: current,
                      color: progress > 1.0 ? Colors.red : Colors.green,
                      title: '${current.toInt()}',
                      radius: 50,
                    ),
                    PieChartSectionData(
                      value: (target - current).clamp(0.0, target),
                      color: Colors.grey[300]!,
                      title: progress >= 1.0 ? '' : '${(target - current).toInt()}',
                      radius: 50,
                    ),
                  ],
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              progress >= 1.0 
                ? 'Target exceeded by ${(current - target).toInt()} kcal'
                : 'Remaining: ${(target - current).toInt()} kcal',
              style: TextStyle(
                color: progress >= 1.0 ? Colors.red : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthStatusCard(Dog selectedDog, double todayCalories, double targetCalories) {
    final status = _getHealthStatus(selectedDog, todayCalories, targetCalories);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  status['icon'] as IconData,
                  color: status['color'] as Color,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  status['title'] as String,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: status['color'] as Color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              status['description'] as String,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildWeeklySummaryCard(List<double> weekData, double target) {
      final average = weekData.reduce((a, b) => a + b) / weekData.length;
    final daysOverTarget = weekData.where((day) => day > target).length;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Average: ${average.toInt()} kcal/day',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Days over target: $daysOverTarget/7'),
            const SizedBox(height: 8),
            Text(
              average > target 
                ? 'Consider reducing portion sizes'
                : 'Good calorie management!',
              style: TextStyle(
                color: average > target ? Colors.orange : Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  recommendation['icon'] as IconData,
                  color: recommendation['color'] as Color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendation['title'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              recommendation['description'] as String,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getWeeklyAverageCalories(String dogId, MealProvider mealProvider) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    final weekMeals = mealProvider.meals.where((Meal meal) =>
        meal.dogId == dogId &&
        meal.mealTime.isAfter(weekAgo) &&
        meal.mealTime.isBefore(now.add(const Duration(days: 1)))
    ).toList();
    
    if (weekMeals.isEmpty) return 0.0;
    
    final totalCalories = weekMeals.fold(0.0, (sum, meal) => sum + meal.calories);
    return totalCalories / 7;
  }

  List<double> _getLast7DaysData(String dogId, MealProvider mealProvider) {
    final data = <double>[];
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayCalories = mealProvider.getTotalCaloriesForDate(dogId, date);
      data.add(dayCalories);
    }
    
    return data;
  }

  Map<String, dynamic> _getHealthStatus(Dog selectedDog, double todayCalories, double targetCalories) {
    final ratio = targetCalories > 0 ? todayCalories / targetCalories : 0.0;
    
    if (ratio < 0.8) {
      return {
        'title': 'Under-eating',
        'description': 'Your dog may not be getting enough calories. Consider increasing portion sizes or adding healthy snacks.',
        'icon': Icons.warning,
        'color': Colors.orange,
      };
    } else if (ratio > 1.2) {
      return {
        'title': 'Over-eating',
        'description': 'Your dog is consuming more calories than recommended. This could lead to weight gain.',
        'icon': Icons.error,
        'color': Colors.red,
      };
    } else {
      return {
        'title': 'Healthy Range',
        'description': 'Your dog is consuming an appropriate amount of calories for their size and activity level.',
        'icon': Icons.check_circle,
        'color': Colors.green,
      };
    }
  }

  List<Map<String, dynamic>> _generateRecommendations(Dog selectedDog, MealProvider mealProvider) {
    final recommendations = <Map<String, dynamic>>[];
    final now = DateTime.now();
    final todayCalories = mealProvider.getTotalCaloriesForDate(selectedDog.id, now);
    final targetCalories = selectedDog.dailyCaloricNeeds;
    final weeklyAverage = _getWeeklyAverageCalories(selectedDog.id, mealProvider);
    
    // Calorie-based recommendations
    if (todayCalories > targetCalories * 1.2) {
      recommendations.add({
        'title': 'Reduce Portion Sizes',
        'description': 'Your dog is consuming ${(todayCalories - targetCalories).toInt()} calories above their daily target. Consider reducing meal portions by 10-15%.',
        'icon': Icons.remove_circle_outline,
        'color': Colors.red,
      });
    } else if (todayCalories < targetCalories * 0.8) {
      recommendations.add({
        'title': 'Increase Food Intake',
        'description': 'Your dog needs ${(targetCalories - todayCalories).toInt()} more calories today. Add a healthy snack or increase meal portions.',
        'icon': Icons.add_circle_outline,
        'color': Colors.orange,
      });
    }
    
    // Activity-based recommendations
    if (selectedDog.activityLevel == 'low') {
      recommendations.add({
        'title': 'Increase Exercise',
        'description': 'Low activity dogs benefit from regular walks. Try adding 15-20 minutes of daily exercise to improve health and manage weight.',
        'icon': Icons.directions_walk,
        'color': Colors.blue,
      });
    }
    
    // Age-based recommendations
    if (selectedDog.age < 12) {
      recommendations.add({
        'title': 'Puppy Nutrition',
        'description': 'Growing puppies need more calories per pound than adult dogs. Ensure you\'re feeding a high-quality puppy food.',
        'icon': Icons.child_care,
        'color': Colors.green,
      });
    } else if (selectedDog.age > 84) { // 7+ years
      recommendations.add({
        'title': 'Senior Dog Care',
        'description': 'Senior dogs may need fewer calories but more frequent meals. Consider switching to a senior dog food formula.',
        'icon': Icons.elderly,
        'color': Colors.purple,
      });
    }
    
    // Weight-based recommendations
    if (selectedDog.weight > 30) {
      recommendations.add({
        'title': 'Large Breed Considerations',
        'description': 'Large dogs are prone to joint issues. Ensure adequate protein and consider joint supplements after consulting your vet.',
        'icon': Icons.pets,
        'color': Colors.brown,
      });
    }
    
    // Consistency recommendations
    final recentMeals = mealProvider.meals
        .where((Meal meal) => meal.dogId == selectedDog.id)
        .where((Meal meal) => meal.mealTime.isAfter(now.subtract(const Duration(days: 3))))
        .toList();
    
    if (recentMeals.length < 6) { // Less than 2 meals per day
      recommendations.add({
        'title': 'Meal Frequency',
        'description': 'Dogs benefit from regular meal schedules. Try to feed your dog 2-3 times per day at consistent times.',
        'icon': Icons.schedule,
        'color': Colors.indigo,
      });
    }
    
    // Weekly trend recommendations
    if (weeklyAverage > targetCalories * 1.15) {
      recommendations.add({
        'title': 'Weekly Calorie Management',
        'description': 'Your dog has been consistently over their calorie target this week. Consider meal planning to better control portions.',
        'icon': Icons.trending_down,
        'color': Colors.red,
      });
    }
    
    // General health recommendations
    recommendations.add({
      'title': 'Regular Vet Checkups',
      'description': 'Schedule regular veterinary checkups to monitor your dog\'s weight and overall health. Discuss any dietary concerns with your vet.',
      'icon': Icons.local_hospital,
      'color': Colors.teal,
    });
    
    recommendations.add({
      'title': 'Fresh Water',
      'description': 'Always ensure your dog has access to fresh, clean water. Proper hydration is essential for digestion and overall health.',
      'icon': Icons.water_drop,
      'color': Colors.cyan,
    });
    
    return recommendations;
  }
}

