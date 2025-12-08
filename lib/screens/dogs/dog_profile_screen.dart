import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pupshape/providers/dog_provider.dart';
import 'package:pupshape/models/dog.dart';
import 'package:pupshape/widgets/custom_text_field.dart';
import 'package:pupshape/widgets/custom_button.dart';

class DogProfileScreen extends StatefulWidget {
  final Dog? dog;
  
  const DogProfileScreen({super.key, this.dog});

  @override
  State<DogProfileScreen> createState() => _DogProfileScreenState();
}

class _DogProfileScreenState extends State<DogProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  
  String _selectedGender = 'male';
  String _selectedActivityLevel = 'moderate';
  bool _isNeutered = false;
  List<String> _allergies = [];
  List<String> _healthConditions = [];
  
  // NEW: Feeding schedule variables
  int _mealsPerDay = 2;
  bool _enableMealReminders = true;
  int _reminderMinutesBefore = 30;
  Map<String, TimeOfDay> _mealTimes = {
    'breakfast': const TimeOfDay(hour: 8, minute: 0),
    'dinner': const TimeOfDay(hour: 18, minute: 0),
  };
  
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.dog != null;
    if (_isEditing) {
      _populateFields();
    }
  }

  void _populateFields() {
    final dog = widget.dog!;
    _nameController.text = dog.name;
    _breedController.text = dog.breed;
    _ageController.text = dog.age.toString();
    _weightController.text = dog.weight.toString();
    _selectedGender = dog.gender;
    _selectedActivityLevel = dog.activityLevel;
    _isNeutered = dog.isNeutered;
    _allergies = List.from(dog.allergies);
    _healthConditions = List.from(dog.healthConditions);
    
    // NEW: Populate feeding schedule
    _mealsPerDay = dog.mealsPerDay;
    _enableMealReminders = dog.enableMealReminders;
    _reminderMinutesBefore = dog.reminderMinutesBefore;
    
    // Convert meal schedule to TimeOfDay
    _mealTimes.clear();
    dog.mealSchedule.forEach((mealType, timeMap) {
      _mealTimes[mealType] = TimeOfDay(
        hour: timeMap['hour']!,
        minute: timeMap['minute']!,
      );
    });
  }

  void _updateMealSchedule() {
    _mealTimes.clear();
    
    if (_mealsPerDay == 2) {
      _mealTimes = {
        'breakfast': _mealTimes['breakfast'] ?? const TimeOfDay(hour: 8, minute: 0),
        'dinner': _mealTimes['dinner'] ?? const TimeOfDay(hour: 18, minute: 0),
      };
    } else if (_mealsPerDay == 3) {
      _mealTimes = {
        'breakfast': _mealTimes['breakfast'] ?? const TimeOfDay(hour: 8, minute: 0),
        'lunch': _mealTimes['lunch'] ?? const TimeOfDay(hour: 13, minute: 0),
        'dinner': _mealTimes['dinner'] ?? const TimeOfDay(hour: 18, minute: 0),
      };
    } else if (_mealsPerDay == 4) {
      _mealTimes = {
        'breakfast': _mealTimes['breakfast'] ?? const TimeOfDay(hour: 8, minute: 0),
        'lunch': _mealTimes['lunch'] ?? const TimeOfDay(hour: 13, minute: 0),
        'dinner': _mealTimes['dinner'] ?? const TimeOfDay(hour: 18, minute: 0),
        'evening_snack': _mealTimes['evening_snack'] ?? const TimeOfDay(hour: 21, minute: 0),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit ${widget.dog!.name}' : 'Add New Dog'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfoSection(),
                const SizedBox(height: 24),
                _buildPhysicalInfoSection(),
                const SizedBox(height: 24),
                _buildHealthInfoSection(),
                const SizedBox(height: 24),
                // NEW: Feeding Schedule Section
                _buildFeedingScheduleSection(),
                const SizedBox(height: 32),
                _buildSaveButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pets,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Basic Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _nameController,
            labelText: 'Dog Name',
            hintText: 'Enter your dog\'s name',
            prefixIcon: Icons.pets,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your dog\'s name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _breedController,
            labelText: 'Breed',
            hintText: 'e.g., Golden Retriever, Mixed',
            prefixIcon: Icons.category,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your dog\'s breed';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _ageController,
                  labelText: 'Age (months)',
                  hintText: '12',
                  prefixIcon: Icons.cake,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter age';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  controller: _weightController,
                  labelText: 'Weight (kg)',
                  hintText: '25.5',
                  prefixIcon: Icons.monitor_weight,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter weight';
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
        ],
      ),
    );
  }

  Widget _buildPhysicalInfoSection() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Physical Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Gender',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Male'),
                  value: 'male',
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Female'),
                  value: 'female',
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Activity Level',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedActivityLevel,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low - Mostly indoor, minimal exercise')),
                  DropdownMenuItem(value: 'moderate', child: Text('Moderate - Daily walks, some play')),
                  DropdownMenuItem(value: 'high', child: Text('High - Very active, lots of exercise')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedActivityLevel = value!;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Neutered/Spayed'),
            subtitle: const Text('Affects caloric needs calculation'),
            value: _isNeutered,
            onChanged: (value) {
              setState(() {
                _isNeutered = value!;
              });
            },
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthInfoSection() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.health_and_safety,
                  color: Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Health Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Allergies (Optional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Common: Chicken, Beef, Wheat, Corn, Dairy',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _allergies.map((allergy) => Chip(
              label: Text(allergy),
              onDeleted: () {
                setState(() {
                                  _allergies.remove(allergy);
                });
              },
            )).toList(),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _showAddAllergyDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Allergy'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Health Conditions (Optional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'e.g., Diabetes, Hip Dysplasia, Heart Disease',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _healthConditions.map((condition) => Chip(
              label: Text(condition),
              onDeleted: () {
                setState(() {
                  _healthConditions.remove(condition);
                });
              },
            )).toList(),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _showAddHealthConditionDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Health Condition'),
          ),
        ],
      ),
    );
  }

  // NEW: Feeding Schedule Section
  Widget _buildFeedingScheduleSection() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.schedule,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Feeding Schedule',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Meals per day selector
          const Text(
            'Meals per day',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [2, 3, 4].map((count) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text('$count meals'),
                  selected: _mealsPerDay == count,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _mealsPerDay = count;
                        _updateMealSchedule();
                      });
                    }
                  },
                  selectedColor: const Color(0xFF6366F1).withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _mealsPerDay == count 
                        ? const Color(0xFF6366F1) 
                        : Colors.grey.shade600,
                    fontWeight: _mealsPerDay == count 
                        ? FontWeight.bold 
                        : FontWeight.normal,
                  ),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 20),
          
          // Meal times
          const Text(
            'Meal times',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          ..._mealTimes.entries.map((entry) => _buildMealTimeRow(entry.key, entry.value)),
          
          const SizedBox(height: 20),
          
          // Reminder settings
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications, color: Color(0xFF6366F1), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Meal Reminders',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: _enableMealReminders,
                      onChanged: (value) {
                        setState(() {
                          _enableMealReminders = value;
                        });
                      },
                      activeColor: const Color(0xFF6366F1),
                    ),
                  ],
                ),
                if (_enableMealReminders) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Remind me before meal time',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [15, 30, 60].map((minutes) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: ChoiceChip(
                          label: Text('${minutes}min'),
                          selected: _reminderMinutesBefore == minutes,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _reminderMinutesBefore = minutes;
                              });
                            }
                          },
                          selectedColor: const Color(0xFF6366F1).withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: _reminderMinutesBefore == minutes 
                                ? const Color(0xFF6366F1) 
                                : Colors.grey.shade600,
                            fontWeight: _reminderMinutesBefore == minutes 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealTimeRow(String mealType, TimeOfDay time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 100,
            child: Text(
              mealType.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: () => _selectMealTime(mealType, time),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Color(0xFF6366F1), size: 20),
                    const SizedBox(width: 12),
                    Text(
                      time.format(context),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.edit, color: Colors.grey, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectMealTime(String mealType, TimeOfDay currentTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6366F1),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != currentTime) {
      setState(() {
        _mealTimes[mealType] = picked;
      });
    }
  }

  Widget _buildSaveButton() {
    return CustomButton(
      text: _isEditing ? 'Update Dog Profile' : 'Add Dog',
      onPressed: _isLoading ? null : _saveDog,
      isLoading: _isLoading,
      width: double.infinity,
      icon: _isEditing ? Icons.update : Icons.add,
    );
  }

  Future<void> _saveDog() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Convert TimeOfDay to Map<String, int> for storage
      final Map<String, Map<String, int>> mealScheduleMap = {};
      _mealTimes.forEach((mealType, time) {
        mealScheduleMap[mealType] = {
          'hour': time.hour,
          'minute': time.minute,
        };
      });

      final dog = Dog(
        id: _isEditing ? widget.dog!.id : '',
        name: _nameController.text.trim(),
        breed: _breedController.text.trim(),
        age: int.parse(_ageController.text),
        weight: double.parse(_weightController.text),
        activityLevel: _selectedActivityLevel,
        gender: _selectedGender,
        isNeutered: _isNeutered,
        allergies: _allergies,
        healthConditions: _healthConditions,
        imageUrl: _isEditing ? widget.dog!.imageUrl : '',
        createdAt: _isEditing ? widget.dog!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        // NEW: Feeding schedule data
        mealSchedule: mealScheduleMap,
        mealsPerDay: _mealsPerDay,
        enableMealReminders: _enableMealReminders,
        reminderMinutesBefore: _reminderMinutesBefore,
      );

      final dogProvider = Provider.of<DogProvider>(context, listen: false);
      
      if (_isEditing) {
        await dogProvider.updateDog(dog);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${dog.name}\'s profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await dogProvider.addDog(dog);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${dog.name} added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAddAllergyDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Allergy'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter allergy (e.g., Chicken)',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final allergy = controller.text.trim();
              if (allergy.isNotEmpty && !_allergies.contains(allergy)) {
                setState(() {
                  _allergies.add(allergy);
                });
              }
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddHealthConditionDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Health Condition'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter condition (e.g., Diabetes)',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final condition = controller.text.trim();
              if (condition.isNotEmpty && !_healthConditions.contains(condition)) {
                setState(() {
                  _healthConditions.add(condition);
                });
              }
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }
}
