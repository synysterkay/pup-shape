import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pupshape/providers/dog_provider.dart';
import 'package:pupshape/services/progress_service.dart';
import 'package:pupshape/widgets/custom_button.dart';
import 'package:pupshape/widgets/custom_text_field.dart';

class WeightLoggingScreen extends StatefulWidget {
  const WeightLoggingScreen({super.key});

  @override
  State<WeightLoggingScreen> createState() => _WeightLoggingScreenState();
}

class _WeightLoggingScreenState extends State<WeightLoggingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  final ProgressService _progressService = ProgressService();
  
  double? _bodyConditionScore;
  bool _isLoading = false;

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _logWeight() async {
    if (!_formKey.currentState!.validate()) return;

    final dogProvider = Provider.of<DogProvider>(context, listen: false);
    final dog = dogProvider.selectedDog;

    if (dog == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No dog selected'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _progressService.logWeight(
        dogId: dog.id,
        weight: double.parse(_weightController.text),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        bodyConditionScore: _bodyConditionScore,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Weight logged successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging weight: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Weight'),
        backgroundColor: Colors.white,
        elevation: 0,
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
                  final dog = dogProvider.selectedDog;
                  if (dog == null) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No dog selected'),
                      ),
                    );
                  }

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF6366F1),
                            child: Text(
                              dog.name[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dog.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Last: ${dog.weight.toStringAsFixed(1)} kg',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
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
              ),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _weightController,
                labelText: 'Weight (kg)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter weight';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  final weight = double.parse(value);
                  if (weight <= 0 || weight > 200) {
                    return 'Please enter a realistic weight';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Body Condition Score (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '1-9 scale: 1 = Very thin, 5 = Ideal, 9 = Obese',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: List.generate(9, (index) {
                  final score = (index + 1).toDouble();
                  final isSelected = _bodyConditionScore == score;
                  return ChoiceChip(
                    label: Text(score.toInt().toString()),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _bodyConditionScore = selected ? score : null;
                      });
                    },
                    selectedColor: const Color(0xFF6366F1),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _notesController,
                labelText: 'Notes (Optional)',
                maxLines: 3,
                hintText: 'Any observations? e.g., "More energy today"',
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tips_and_updates, color: Colors.blue),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Weighing Tips',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Weigh at the same time each week\n'
                      '• Use the same scale\n'
                      '• Weigh before meals for accuracy\n'
                      '• Weekly weigh-ins are recommended',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Log Weight',
                onPressed: _isLoading ? null : _logWeight,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
