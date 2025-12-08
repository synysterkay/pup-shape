import 'package:flutter/material.dart';

enum MilestoneType {
  weightLoss25,
  weightLoss50,
  weightLoss75,
  weightLossGoal,
  streak7Days,
  streak30Days,
  streak90Days,
  firstMeal,
  hundredthMeal,
  perfectWeek,
}

class Milestone {
  final String id;
  final String dogId;
  final MilestoneType type;
  final String title;
  final String description;
  final String iconEmoji;
  final DateTime achievedAt;
  final bool isCelebrated;

  Milestone({
    required this.id,
    required this.dogId,
    required this.type,
    required this.title,
    required this.description,
    required this.iconEmoji,
    required this.achievedAt,
    this.isCelebrated = false,
  });

  Color getColor() {
    switch (type) {
      case MilestoneType.weightLoss25:
        return Colors.blue;
      case MilestoneType.weightLoss50:
        return Colors.orange;
      case MilestoneType.weightLoss75:
        return Colors.purple;
      case MilestoneType.weightLossGoal:
        return Colors.green;
      case MilestoneType.streak7Days:
      case MilestoneType.streak30Days:
      case MilestoneType.streak90Days:
        return Colors.red;
      case MilestoneType.firstMeal:
      case MilestoneType.hundredthMeal:
      case MilestoneType.perfectWeek:
        return Colors.amber;
    }
  }

  static Milestone create({
    required String dogId,
    required MilestoneType type,
  }) {
    final now = DateTime.now();
    final id = '${dogId}_${type.name}_${now.millisecondsSinceEpoch}';

    String title, description, emoji;
    switch (type) {
      case MilestoneType.weightLoss25:
        title = '25% Progress';
        description = 'Quarter of the way there!';
        emoji = '🎯';
        break;
      case MilestoneType.weightLoss50:
        title = 'Halfway Hero';
        description = 'You\'ve reached 50% of the goal!';
        emoji = '⭐';
        break;
      case MilestoneType.weightLoss75:
        title = '75% Champion';
        description = 'Almost there! Keep going!';
        emoji = '🏆';
        break;
      case MilestoneType.weightLossGoal:
        title = 'Goal Achieved!';
        description = 'Target weight reached! Amazing work!';
        emoji = '🎉';
        break;
      case MilestoneType.streak7Days:
        title = '7-Day Streak';
        description = 'One week of consistency!';
        emoji = '🔥';
        break;
      case MilestoneType.streak30Days:
        title = '30-Day Streak';
        description = 'A full month of dedication!';
        emoji = '💪';
        break;
      case MilestoneType.streak90Days:
        title = '90-Day Legend';
        description = 'Three months of excellence!';
        emoji = '👑';
        break;
      case MilestoneType.firstMeal:
        title = 'First Meal Logged';
        description = 'Great start to a healthier journey!';
        emoji = '🍽️';
        break;
      case MilestoneType.hundredthMeal:
        title = '100 Meals Logged';
        description = 'Incredible tracking dedication!';
        emoji = '💯';
        break;
      case MilestoneType.perfectWeek:
        title = 'Perfect Week';
        description = 'All meals logged this week!';
        emoji = '✨';
        break;
    }

    return Milestone(
      id: id,
      dogId: dogId,
      type: type,
      title: title,
      description: description,
      iconEmoji: emoji,
      achievedAt: now,
    );
  }
}
