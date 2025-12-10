import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pupshape/config/theme.dart';
import 'package:pupshape/models/dog.dart';
import 'package:pupshape/providers/dog_provider.dart';
import 'package:pupshape/providers/plan_provider.dart';
import 'package:pupshape/services/deepseek_service.dart';
import 'package:pupshape/services/test_data_generator.dart';
import 'package:pupshape/widgets/assessment/breed_selector.dart';

class AssessmentWizard extends StatefulWidget {
  const AssessmentWizard({super.key});

  @override
  State<AssessmentWizard> createState() => _AssessmentWizardState();
}

class _AssessmentWizardState extends State<AssessmentWizard> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // Form data
  final _nameController = TextEditingController();
  String _selectedBreed = 'Mixed Breed';
  int _ageYears = 2;
  String _gender = 'Male';
  double _currentWeight = 15.0;
  double _targetWeight = 12.0;
  String _activityLevel = 'Moderate';
  
  bool _isGeneratingPlan = false;

  final List<String> _commonBreeds = [
    'Mixed Breed',
    'Labrador Retriever',
    'Golden Retriever',
    'German Shepherd',
    'Bulldog',
    'Beagle',
    'Poodle',
    'Rottweiler',
    'Yorkshire Terrier',
    'Boxer',
    'Dachshund',
    'Shih Tzu',
    'Chihuahua',
    'Pomeranian',
    'Husky',
    'Corgi',
  ];

  final List<String> _activityLevels = [
    'Sedentary',
    'Light',
    'Moderate',
    'Active',
    'Very Active',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _generatePlan();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  // TEST ONLY - Remove before production
  Future<void> _generateTestPlan() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your dog\'s name')),
      );
      return;
    }

    setState(() => _isGeneratingPlan = true);

    try {
      // Create dog profile
      final dog = Dog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        breed: _selectedBreed,
        age: _ageYears,
        weight: _currentWeight,
        targetWeight: _targetWeight,
        gender: _gender,
        activityLevel: _activityLevel,
        isNeutered: false,
        allergies: [],
        healthConditions: [],
        imageUrl: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        mealSchedule: {
          'breakfast': {'hour': 8, 'minute': 0},
          'dinner': {'hour': 18, 'minute': 0},
        },
        mealsPerDay: 2,
        enableMealReminders: false,
        reminderMinutesBefore: 30,
      );

      // Save to provider
      final dogProvider = Provider.of<DogProvider>(context, listen: false);
      await dogProvider.addDog(dog);
      await dogProvider.setActiveDog(dog);

      // Generate test meal plan
      final planProvider = Provider.of<PlanProvider>(context, listen: false);
      final testPlan = TestDataGenerator.getMockWeightLossPlan(
        dogId: dog.id,
        dogName: dog.name,
        currentWeight: _currentWeight,
        targetWeight: _targetWeight,
      );
      await planProvider.savePlan(testPlan);

      if (mounted) {
        setState(() => _isGeneratingPlan = false);
        
        // Navigate to home with success message
        Navigator.of(context).pushReplacementNamed('/home');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Test plan created for ${dog.name}! Ready for screenshots'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isGeneratingPlan = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _generatePlan() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your dog\'s name')),
      );
      return;
    }

    setState(() => _isGeneratingPlan = true);

    // Show loading dialog with progress logs
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PlanGenerationDialog(dogName: _nameController.text.trim()),
    );

    try {
      // Call DeepSeek AI to generate personalized plan
      final deepSeekService = DeepSeekService();
      final plan = await deepSeekService.generateWeightPlan(
        breed: _selectedBreed,
        currentWeight: _currentWeight,
        targetWeight: _targetWeight,
        ageYears: _ageYears,
        activityLevel: _activityLevel,
        gender: _gender,
      );

      // Create dog profile with AI-generated data
      final dog = Dog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        breed: _selectedBreed,
        age: _ageYears,
        weight: _currentWeight,
        targetWeight: _targetWeight,
        gender: _gender,
        activityLevel: _activityLevel,
        isNeutered: false,
        allergies: [],
        healthConditions: [],
        imageUrl: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        mealSchedule: {
          'breakfast': {'hour': 8, 'minute': 0},
          'dinner': {'hour': 18, 'minute': 0},
        },
        mealsPerDay: 2,
        enableMealReminders: false,
        reminderMinutesBefore: 30,
      );

      // Save to provider
      final dogProvider = Provider.of<DogProvider>(context, listen: false);
      await dogProvider.addDog(dog);
      await dogProvider.setActiveDog(dog);

      // Generate mock meal plan
      final planProvider = Provider.of<PlanProvider>(context, listen: false);
      
      try {
        // Generate mock plan using current weight from dog profile
        final mockPlan = planProvider.generateMockPlan(dog.id, dog.weight, dog.targetWeight ?? dog.weight - 5);
        await planProvider.savePlan(mockPlan);
      } catch (e) {
        // If saving fails, log error
        print('Error generating meal plan: $e');
      }

      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();
        
        // Navigate to home with success message
        Navigator.of(context).pushReplacementNamed('/home');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 ${dog.name}\'s 12-week plan is ready! Target: ${plan.estimatedWeeksToGoal} weeks to goal.',
            ),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() => _isGeneratingPlan = false);
      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating plan: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.backgroundColor,
              AppTheme.primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress Indicator
              _buildProgressBar(),
              
              // Content with animation
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) => setState(() => _currentStep = index),
                  children: [
                    _buildStep1BasicInfo(),
                    _buildStep2WeightGoals(),
                    _buildStep3ActivityLevel(),
                    _buildStep4AIGenerating(),
                  ],
                ),
              ),
              
              // Navigation Buttons
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Row(
            children: [
              if (_currentStep > 0)
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.primaryColor),
                    onPressed: _previousStep,
                  ),
                )
              else
                const SizedBox(width: 48),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Step ${_currentStep + 1} of 4',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Animated progress dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              4,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: index == _currentStep ? 40 : 10,
                height: 10,
                decoration: BoxDecoration(
                  gradient: index <= _currentStep
                      ? AppTheme.primaryGradient
                      : null,
                  color: index <= _currentStep
                      ? null
                      : AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1BasicInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Who are we helping?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell us about your furry friend',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 32),
          
          // Animated Dog Icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (value * 0.2),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    width: 80,
                    height: 80,
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
                      Icons.pets_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          
          // Name with modern styling
          Container(
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
            child: TextField(
              controller: _nameController,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                labelText: 'Dog\'s Name',
                labelStyle: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 14,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.pets_rounded, color: AppTheme.primaryColor, size: 20),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ),
          const SizedBox(height: 24),
          
          // Breed Selector
          BreedSelector(
            selectedBreed: _selectedBreed,
            onBreedSelected: (breed) => setState(() => _selectedBreed = breed),
          ),
          const SizedBox(height: 20),
          
          // Age
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Age: $_ageYears years',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              Slider(
                value: _ageYears.toDouble(),
                min: 0,
                max: 20,
                divisions: 20,
                activeColor: AppTheme.primaryColor,
                label: '$_ageYears years',
                onChanged: (value) => setState(() => _ageYears = value.toInt()),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Gender
          const Text(
            'Gender',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildGenderOption('Male', Icons.male),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGenderOption('Female', Icons.female),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String gender, IconData icon) {
    final isSelected = _gender == gender;
    return AnimatedScale(
      scale: isSelected ? 1.0 : 0.95,
      duration: const Duration(milliseconds: 200),
      child: InkWell(
        onTap: () => setState(() => _gender = gender),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            gradient: isSelected ? AppTheme.primaryGradient : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.grey.shade300,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: isSelected ? Colors.white : AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                gender,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep2WeightGoals() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'The Weigh-In',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Set weight goals for optimal health',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 40),
          
          // Current Weight
          Container(
            padding: const EdgeInsets.all(24),
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
                const Text(
                  'Current Weight',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${_currentWeight.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentColor,
                  ),
                ),
                Slider(
                  value: _currentWeight,
                  min: 1,
                  max: 80,
                  divisions: 158,
                  activeColor: AppTheme.accentColor,
                  label: '${_currentWeight.toStringAsFixed(1)} kg',
                  onChanged: (value) {
                    setState(() {
                      _currentWeight = value;
                      if (_targetWeight > _currentWeight) {
                        _targetWeight = _currentWeight;
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Target Weight
          Container(
            padding: const EdgeInsets.all(24),
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
                const Text(
                  'Target Weight',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${_targetWeight.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Slider(
                  value: _targetWeight,
                  min: 1,
                  max: _currentWeight,
                  divisions: ((_currentWeight - 1) * 2).toInt(),
                  activeColor: AppTheme.primaryColor,
                  label: '${_targetWeight.toStringAsFixed(1)} kg',
                  onChanged: (value) => setState(() => _targetWeight = value),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Weight Difference
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.trending_down, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Goal: Lose ${(_currentWeight - _targetWeight).toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3ActivityLevel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity Level',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'How active is your dog?',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 32),
          
          ..._activityLevels.map((level) => _buildActivityOption(level)).toList(),
        ],
      ),
    );
  }

  Widget _buildActivityOption(String level) {
    final isSelected = _activityLevel == level;
    final descriptions = {
      'Sedentary': 'Minimal exercise, mostly resting',
      'Light': '1-2 short walks per day',
      'Moderate': '2-3 walks, light play',
      'Active': 'Daily runs, active play',
      'Very Active': 'Working/sporting dog, intense exercise',
    };
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _activityLevel = level),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.directions_run,
                color: isSelected ? Colors.white : AppTheme.primaryColor,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descriptions[level]!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? Colors.white.withOpacity(0.9) : AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep4AIGenerating() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Ready to Generate Plan?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Our AI will analyze ${_nameController.text.isEmpty ? "your dog's" : "${_nameController.text}'s"} profile and create a personalized weight management plan.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          
          // Summary Card
          Container(
            padding: const EdgeInsets.all(20),
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
                _buildSummaryRow('Name', _nameController.text.isEmpty ? 'Not set' : _nameController.text),
                _buildSummaryRow('Breed', _selectedBreed),
                _buildSummaryRow('Age', '$_ageYears years'),
                _buildSummaryRow('Current Weight', '${_currentWeight.toStringAsFixed(1)} kg'),
                _buildSummaryRow('Target Weight', '${_targetWeight.toStringAsFixed(1)} kg'),
                _buildSummaryRow('Activity', _activityLevel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isGeneratingPlan ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  side: const BorderSide(color: AppTheme.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          // TEST BUTTON - Remove before production
          if (_currentStep == 3)
            Expanded(
              child: OutlinedButton(
                onPressed: _isGeneratingPlan ? null : _generateTestPlan,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Test Plan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (_currentStep == 3) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isGeneratingPlan ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isGeneratingPlan
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _currentStep == 3 ? 'Generate Plan' : 'Continue',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// Loading dialog widget with animated progress logs
class _PlanGenerationDialog extends StatefulWidget {
  final String dogName;
  
  const _PlanGenerationDialog({required this.dogName});

  @override
  State<_PlanGenerationDialog> createState() => _PlanGenerationDialogState();
}

class _PlanGenerationDialogState extends State<_PlanGenerationDialog> with TickerProviderStateMixin {
  final List<String> _logs = [];
  int _currentLogIndex = 0;
  late AnimationController _dotsController;
  
  final List<String> _allLogs = [
    '🔍 Analyzing breed characteristics...',
    '📊 Calculating optimal caloric needs...',
    '🤖 Consulting AI...',
    '🍖 Generating meal recommendations...',
    '📅 Creating 12-week schedule...',
    '💪 Tailoring exercise suggestions...',
    '📈 Setting weight milestones...',
    '✨ Finalizing personalized plan...',
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
      await Future.delayed(Duration(milliseconds: 600 + (i * 100)));
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
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.psychology,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Creating ${widget.dogName}\'s Plan',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
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
                    color: AppTheme.textSecondaryColor,
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
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Progress percentage
            Text(
              '${((_currentLogIndex + 1) / _allLogs.length * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Log container
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
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
                      duration: const Duration(milliseconds: 400),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 10 * (1 - value)),
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
                                        ? AppTheme.primaryColor
                                        : AppTheme.successColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      log,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: index == _logs.length - 1
                                            ? AppTheme.textPrimaryColor
                                            : AppTheme.textSecondaryColor,
                                        fontWeight: index == _logs.length - 1
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
