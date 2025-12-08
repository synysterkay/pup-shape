import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pupshape/providers/dog_provider.dart';
import 'package:pupshape/providers/meal_provider.dart';
import 'package:pupshape/models/meal.dart';
import 'package:pupshape/widgets/custom_button.dart';
import 'package:pupshape/widgets/custom_text_field.dart';

class MealLoggingScreen extends StatefulWidget {
  final Meal? meal;

  const MealLoggingScreen({super.key, this.meal});

  @override
  State<MealLoggingScreen> createState() => _MealLoggingScreenState();
}

class _MealLoggingScreenState extends State<MealLoggingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _foodNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime _selectedDateTime = DateTime.now();
  String _selectedMealType = 'breakfast';
  
  bool get _isEditing => widget.meal != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _populateFields();
    }
  }

  void _populateFields() {
    final meal = widget.meal!;
    _foodNameController.text = meal.foodName;
    _quantityController.text = meal.portionSize.toString(); // Changed from quantity to portionSize
    _caloriesController.text = meal.calories.toString();
    _notesController.text = meal.notes ?? '';
    _selectedDateTime = meal.mealTime;
    _selectedMealType = meal.mealType;
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _quantityController.dispose();
    _caloriesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveMeal() async {
    if (_formKey.currentState!.validate()) {
      final dogProvider = Provider.of<DogProvider>(context, listen: false);
      final mealProvider = Provider.of<MealProvider>(context, listen: false);
      
      if (dogProvider.selectedDog == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a dog first'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final meal = Meal(
        id: _isEditing ? widget.meal!.id : '',
        dogId: dogProvider.selectedDog!.id,
        foodName: _foodNameController.text.trim(),
        portionSize: double.parse(_quantityController.text), // Changed from quantity to portionSize
        calories: double.parse(_caloriesController.text),
        mealType: _selectedMealType,
        mealTime: _selectedDateTime,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: _isEditing ? widget.meal!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool success;
      if (_isEditing) {
        success = await mealProvider.updateMeal(meal);
      } else {
        success = await mealProvider.addMeal(meal);
      }

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Meal updated successfully!' : 'Meal logged successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mealProvider.errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Meal' : 'Log Meal'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _showDeleteDialog,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Consumer<DogProvider>(
                builder: (context, dogProvider, child) {
                  if (dogProvider.selectedDog == null) {
                    return Card(
                      color: Colors.orange[50],
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Please select a dog from the home screen first',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    );
                  }
                  
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Text(
                              dogProvider.selectedDog!.name[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Logging meal for ${dogProvider.selectedDog!.name}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _foodNameController,
                labelText: 'Food Name',
                prefixIcon: Icons.restaurant,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the food name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _quantityController,
                      labelText: 'Quantity (g)',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.scale,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter quantity';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _caloriesController,
                      labelText: 'Calories',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.local_fire_department,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter calories';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedMealType,
                decoration: const InputDecoration(
                  labelText: 'Meal Type',
                  prefixIcon: Icon(Icons.schedule),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'breakfast', child: Text('Breakfast')),
                  DropdownMenuItem(value: 'lunch', child: Text('Lunch')),
                  DropdownMenuItem(value: 'dinner', child: Text('Dinner')),
                  DropdownMenuItem(value: 'snack', child: Text('Snack')),
                  DropdownMenuItem(value: 'treat', child: Text('Treat')),
                ],
                onChanged: (String? value) {
                  setState(() {
                    _selectedMealType = value ?? 'breakfast';
                  });
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDateTime,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time),
                      const SizedBox(width: 12),
                      Text(
                        'Date & Time: ${_selectedDateTime.day}/${_selectedDateTime.month}/${_selectedDateTime.year} ${_selectedDateTime.hour.toString().padLeft(2, '0')}:${_selectedDateTime.minute.toString().padLeft(2, '0')}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _notesController,
                labelText: 'Notes (optional)',
                maxLines: 3,
                prefixIcon: Icons.note,
              ),
              const SizedBox(height: 32),
              Consumer<MealProvider>(
                builder: (context, mealProvider, child) {
                  return CustomButton(
                    text: _isEditing ? 'Update Meal' : 'Log Meal',
                    onPressed: mealProvider.isLoading ? null : _saveMeal,
                    isLoading: mealProvider.isLoading,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meal'),
        content: const Text('Are you sure you want to delete this meal? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final mealProvider = Provider.of<MealProvider>(context, listen: false);
              final success = await mealProvider.deleteMeal(widget.meal!.id);
              
              if (success && mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Meal deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
