import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pupshape/models/daily_tip.dart';
import 'package:pupshape/providers/dog_provider.dart';
import 'package:pupshape/services/tips_service.dart';
import 'package:pupshape/services/test_data_generator.dart';
import 'package:pupshape/screens/tips/tip_history_screen.dart';

class DailyTipCard extends StatefulWidget {
  const DailyTipCard({super.key});

  @override
  State<DailyTipCard> createState() => _DailyTipCardState();
}

class _DailyTipCardState extends State<DailyTipCard> {
  final TipsService _tipsService = TipsService();
  DailyTip? _todaysTip;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodaysTip();
  }

  // TEST ONLY - Remove before production
  void _loadTestTip() {
    final dogProvider = Provider.of<DogProvider>(context, listen: false);
    final dog = dogProvider.selectedDog;

    if (dog == null) return;

    setState(() {
      _todaysTip = TestDataGenerator.getMockDailyTip(
        dogId: dog.id,
        dogName: dog.name,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Test tip loaded!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _loadTodaysTip() async {
    final dogProvider = Provider.of<DogProvider>(context, listen: false);
    final dog = dogProvider.selectedDog;

    if (dog == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Try to get cached tip for today
      var tip = await _tipsService.getTodaysTip(dog.id);

      // If no tip exists for today, generate one
      if (tip == null) {
        tip = await _tipsService.generateDailyTip(dog: dog);
      }

      if (mounted) {
        setState(() {
          _todaysTip = tip;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading daily tip: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.withOpacity(0.1),
              Colors.blue.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_todaysTip == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _showTipDetail(context),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getCategoryColor(_todaysTip!.category).withOpacity(0.15),
              _getCategoryColor(_todaysTip!.category).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getCategoryColor(_todaysTip!.category).withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _getCategoryColor(_todaysTip!.category).withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(_todaysTip!.category).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _todaysTip!.getCategoryIcon(),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daily Tip',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          _todaysTip!.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getCategoryColor(_todaysTip!.category),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // TEST BUTTON - Remove before production
                  IconButton(
                    icon: const Icon(Icons.science, size: 20, color: Colors.orange),
                    onPressed: () => _loadTestTip(),
                    tooltip: 'Load test tip',
                  ),
                  IconButton(
                    icon: const Icon(Icons.history, size: 20),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const TipHistoryScreen(),
                        ),
                      );
                    },
                    tooltip: 'View tip history',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _todaysTip!.content,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(_todaysTip!.category).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _todaysTip!.category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getCategoryColor(_todaysTip!.category),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Text(
                    'Tap for more →',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getCategoryColor(_todaysTip!.category),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'motivation':
        return Colors.orange;
      case 'nutrition':
        return Colors.green;
      case 'exercise':
        return Colors.blue;
      case 'health':
        return Colors.red;
      case 'breed':
        return Colors.purple;
      default:
        return const Color(0xFF6366F1);
    }
  }

  void _showTipDetail(BuildContext context) {
    if (_todaysTip == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(_todaysTip!.category).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _todaysTip!.getCategoryIcon(),
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        _todaysTip!.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(_todaysTip!.category).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _todaysTip!.category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getCategoryColor(_todaysTip!.category),
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _todaysTip!.content,
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.6,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'New tip generated daily based on your dog\'s progress!',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[800],
                              ),
                            ),
                          ),
                        ],
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

    // Mark as read
    if (!_todaysTip!.isRead) {
      _tipsService.markTipAsRead(_todaysTip!.id);
    }
  }
}
