import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pupshape/config/theme.dart';

class WeightProgressChart extends StatelessWidget {
  final double currentWeight;
  final double targetWeight;

  const WeightProgressChart({
    super.key,
    required this.currentWeight,
    required this.targetWeight,
  });

  @override
  Widget build(BuildContext context) {
    // Mock data for demonstration - in real app, this would come from historical data
    final spots = _generateMockData();
    
    return Container(
      height: 220,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  Text(
                    '${currentWeight.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.flag,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Goal: ${targetWeight.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 10,
                        );
                        final weeks = ['W1', 'W2', 'W3', 'W4', 'W5', 'W6'];
                        if (value.toInt() >= 0 && value.toInt() < weeks.length) {
                          return Text(weeks[value.toInt()], style: style);
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}kg',
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 5,
                minY: targetWeight - 2,
                maxY: currentWeight + 2,
                lineBarsData: [
                  // Actual progress line
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: AppTheme.primaryGradient,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 6,
                          color: Colors.white,
                          strokeWidth: 3,
                          strokeColor: AppTheme.primaryColor,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.3),
                          AppTheme.primaryColor.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Target line
                  LineChartBarData(
                    spots: List.generate(
                      6,
                      (index) => FlSpot(index.toDouble(), targetWeight),
                    ),
                    isCurved: false,
                    color: AppTheme.accentColor.withOpacity(0.5),
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    dashArray: [5, 5],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generateMockData() {
    // In a real app, this would fetch historical weight data
    // For now, generate a downward trend from current to target
    final weightDiff = currentWeight - targetWeight;
    return List.generate(6, (index) {
      final progress = index / 5;
      final weight = currentWeight - (weightDiff * progress * 0.6); // 60% progress so far
      return FlSpot(index.toDouble(), weight);
    });
  }
}
