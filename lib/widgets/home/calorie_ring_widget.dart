import 'package:flutter/material.dart';
import 'package:pupshape/config/theme.dart';
import 'dart:math' as math;

class CalorieRingWidget extends StatelessWidget {
  final double caloriesConsumed;
  final double caloriesTarget;
  final double caloriesRemaining;
  final double progress;

  const CalorieRingWidget({
    super.key,
    required this.caloriesConsumed,
    required this.caloriesTarget,
    required this.caloriesRemaining,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final isOverTarget = caloriesConsumed > caloriesTarget;
    final displayProgress = isOverTarget ? 1.0 : progress;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Calorie Ring
          SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background Ring
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CustomPaint(
                    painter: _RingPainter(
                      progress: 1.0,
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      strokeWidth: 20,
                    ),
                  ),
                ),
                
                // Progress Ring
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeInOut,
                  tween: Tween(begin: 0.0, end: displayProgress),
                  builder: (context, value, child) {
                    return SizedBox(
                      width: 220,
                      height: 220,
                      child: CustomPaint(
                        painter: _RingPainter(
                          progress: value,
                          color: isOverTarget ? AppTheme.errorColor : AppTheme.primaryColor,
                          strokeWidth: 20,
                        ),
                      ),
                    );
                  },
                ),
                
                // Center Content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<int>(
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeOut,
                      tween: IntTween(begin: 0, end: caloriesRemaining.toInt()),
                      builder: (context, value, child) {
                        return Text(
                          value.toString(),
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: isOverTarget ? AppTheme.errorColor : AppTheme.primaryColor,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOverTarget ? 'Over by' : 'kcal left',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat(
                'Consumed',
                caloriesConsumed,
                AppTheme.accentColor,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.shade300,
              ),
              _buildStat(
                'Target',
                caloriesTarget,
                AppTheme.primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 4),
        TweenAnimationBuilder<int>(
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeOut,
          tween: IntTween(begin: 0, end: value.toInt()),
          builder: (context, animValue, child) {
            return Text(
              animValue.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            );
          },
        ),
        const Text(
          'kcal',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2; // Start from top
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
