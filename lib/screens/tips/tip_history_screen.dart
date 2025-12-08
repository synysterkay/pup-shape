import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pupshape/models/daily_tip.dart';
import 'package:pupshape/providers/dog_provider.dart';
import 'package:pupshape/services/tips_service.dart';

class TipHistoryScreen extends StatefulWidget {
  const TipHistoryScreen({super.key});

  @override
  State<TipHistoryScreen> createState() => _TipHistoryScreenState();
}

class _TipHistoryScreenState extends State<TipHistoryScreen> {
  final TipsService _tipsService = TipsService();
  List<DailyTip> _tips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTipHistory();
  }

  Future<void> _loadTipHistory() async {
    final dogProvider = Provider.of<DogProvider>(context, listen: false);
    final dog = dogProvider.selectedDog;

    if (dog == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final tips = await _tipsService.getTipHistory(dog.id);
      if (mounted) {
        setState(() {
          _tips = tips;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading tip history: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tip History'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tips.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lightbulb_outline, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No tips yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check back tomorrow for your first tip!',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tips.length,
                  itemBuilder: (context, index) {
                    final tip = _tips[index];
                    return _buildTipCard(tip);
                  },
                ),
    );
  }

  Widget _buildTipCard(DailyTip tip) {
    final color = _getCategoryColor(tip.category);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tip.getCategoryIcon(),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        _formatDate(tip.date),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tip.category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              tip.content,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF475569),
              ),
            ),
          ],
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
