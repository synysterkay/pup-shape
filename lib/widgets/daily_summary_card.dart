import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pupshape/providers/dog_provider.dart';
import 'package:pupshape/providers/meal_provider.dart';

class DailySummaryCard extends StatelessWidget {
  const DailySummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<DogProvider, MealProvider>(
      builder: (context, dogProvider, mealProvider, child) {
        final selectedDog = dogProvider.selectedDog;
        if (selectedDog == null) {
          return const SizedBox.shrink();
        }

        final today = DateTime.now();
        final todayCalories = mealProvider.getTotalCaloriesForDate(selectedDog.id, today);
        final targetCalories = selectedDog.dailyCaloricNeeds;
        final progress = targetCalories > 0 ? (todayCalories / targetCalories).clamp(0.0, 1.0) : 0.0;
        final isOverTarget = progress >= 1.0;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isOverTarget 
                  ? [
                      Colors.red.withOpacity(0.1),
                      Colors.orange.withOpacity(0.05),
                    ]
                  : [
                      Colors.green.withOpacity(0.1),
                      Colors.blue.withOpacity(0.05),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isOverTarget 
                  ? Colors.red.withOpacity(0.2)
                  : Colors.green.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isOverTarget 
                            ? Colors.red.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.local_fire_department,
                        color: isOverTarget ? Colors.red : Colors.green,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Today\'s Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Calorie Progress Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Calories Consumed',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '${todayCalories.toInt()}',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: isOverTarget ? Colors.red : const Color(0xFF1E293B),
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' / ${targetCalories.toInt()} kcal',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: Stack(
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isOverTarget ? Colors.red : Colors.green,
                                    ),
                                    strokeWidth: 8,
                                  ),
                                ),
                                Positioned.fill(
                                  child: Center(
                                    child: Text(
                                      '${(progress * 100).toInt()}%',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isOverTarget ? Colors.red : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Progress Bar
                      Container(
                        width: double.infinity,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isOverTarget 
                                    ? [Colors.red, Colors.orange]
                                    : [Colors.green, Colors.blue],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Status Text
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isOverTarget 
                              ? Colors.red.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isOverTarget ? Icons.warning : Icons.check_circle,
                              size: 16,
                              color: isOverTarget ? Colors.red : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                isOverTarget 
                                    ? 'Target exceeded by ${(todayCalories - targetCalories).toInt()} kcal'
                                    : 'Remaining: ${(targetCalories - todayCalories).toInt()} kcal',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isOverTarget ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
