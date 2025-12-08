import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pupshape/config/theme.dart';
import 'package:pupshape/providers/plan_provider.dart';
import 'package:pupshape/providers/dog_provider.dart';
import 'package:pupshape/models/meal_plan.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isWeekView = true;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    final dogProvider = Provider.of<DogProvider>(context, listen: false);
    final planProvider = Provider.of<PlanProvider>(context, listen: false);
    
    if (dogProvider.selectedDog != null) {
      await planProvider.loadPlan(dogProvider.selectedDog!.id);
      
      // If no plan exists, generate a mock one
      if (!planProvider.hasPlan) {
        final mockPlan = planProvider.generateMockPlan(
          dogProvider.selectedDog!.id,
          dogProvider.selectedDog!.weight,
          dogProvider.selectedDog!.targetWeight ?? dogProvider.selectedDog!.weight - 5,
        );
        await planProvider.savePlan(mockPlan);
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
          'Meal Plan',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isWeekView ? Icons.calendar_month : Icons.calendar_view_week,
              color: AppTheme.primaryColor,
            ),
            onPressed: () {
              setState(() {
                _isWeekView = !_isWeekView;
              });
            },
          ),
        ],
      ),
      body: Consumer<PlanProvider>(
        builder: (context, planProvider, child) {
          if (planProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          if (!planProvider.hasPlan) {
            return _buildNoPlanView();
          }

          return RefreshIndicator(
            onRefresh: _loadPlan,
            color: AppTheme.primaryColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildPlanHeader(planProvider.currentPlan!),
                  const SizedBox(height: 16),
                  _buildCalendarSelector(),
                  const SizedBox(height: 24),
                  _buildDailyMeals(planProvider.selectedDayPlan),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoPlanView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'No Meal Plan Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Complete the assessment to generate\nyour personalized 12-week plan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanHeader(WeightLossPlan plan) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '12-Week Plan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Day ${plan.daysCompleted + 1} of ${plan.totalDays}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${plan.progressPercentage.toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: plan.progressPercentage / 100,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPlanStat('Target', '${plan.targetWeight.toStringAsFixed(1)}kg'),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
              _buildPlanStat('Daily Cal', '${plan.dailyCalories} kcal'),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
              _buildPlanStat('Days Left', '${plan.daysRemaining}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarSelector() {
    final weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AppTheme.primaryColor),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                  });
                  Provider.of<PlanProvider>(context, listen: false).selectDate(_selectedDate);
                },
              ),
              Text(
                DateFormat('MMMM yyyy').format(_selectedDate),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: AppTheme.primaryColor),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.add(const Duration(days: 7));
                  });
                  Provider.of<PlanProvider>(context, listen: false).selectDate(_selectedDate);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final date = weekStart.add(Duration(days: index));
              final isSelected = date.day == _selectedDate.day && 
                               date.month == _selectedDate.month;
              final isToday = date.day == DateTime.now().day && 
                            date.month == DateTime.now().month;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                  Provider.of<PlanProvider>(context, listen: false).selectDate(date);
                },
                child: _buildDayCard(date, isSelected, isToday),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(DateTime date, bool isSelected, bool isToday) {
    return Container(
      width: 44,
      height: 60,
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isToday && !isSelected
            ? Border.all(color: AppTheme.primaryColor, width: 2)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('E').format(date).substring(0, 1),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyMeals(DailyMealPlan? dayPlan) {
    if (dayPlan == null) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Text(
          'No meal plan for this date',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('EEEE, MMM d').format(dayPlan.date),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: dayPlan.isFullyLogged 
                      ? AppTheme.primaryColor.withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      dayPlan.isFullyLogged ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 16,
                      color: dayPlan.isFullyLogged ? AppTheme.primaryColor : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${dayPlan.loggedCalories}/${dayPlan.targetCalories} kcal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: dayPlan.isFullyLogged ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (dayPlan.notes != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: AppTheme.accentColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dayPlan.notes!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          ...dayPlan.meals.map((meal) => _buildMealCard(meal)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMealCard(PlannedMeal meal) {
    final IconData icon;
    final Color iconColor;
    
    switch (meal.mealType) {
      case 'breakfast':
        icon = Icons.wb_sunny_outlined;
        iconColor = AppTheme.accentColor;
        break;
      case 'dinner':
        icon = Icons.nightlight_outlined;
        iconColor = AppTheme.primaryColor;
        break;
      case 'treats':
        icon = Icons.favorite_outline;
        iconColor = Colors.pink;
        break;
      default:
        icon = Icons.restaurant;
        iconColor = AppTheme.primaryColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: meal.isLogged 
            ? Border.all(color: AppTheme.primaryColor, width: 2)
            : Border.all(color: Colors.grey.shade200),
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.mealType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondaryColor,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meal.foodName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${meal.calories} kcal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '📦 ${meal.portion}',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: meal.ingredients.map((ingredient) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ingredient,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: meal.isLogged
                    ? null
                    : () async {
                        await Provider.of<PlanProvider>(context, listen: false).logMeal(meal.id);
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${meal.foodName} logged!'),
                              backgroundColor: AppTheme.primaryColor,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: meal.isLogged ? Colors.grey.shade100 : AppTheme.primaryColor,
                  foregroundColor: meal.isLogged ? AppTheme.textSecondaryColor : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      meal.isLogged ? Icons.check_circle : Icons.add_circle_outline,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      meal.isLogged ? 'Logged' : 'Log This Meal',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
