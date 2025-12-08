import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pupshape/models/weight_log.dart';
import 'package:pupshape/models/milestone.dart';

class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Log a weight entry
  Future<WeightLog> logWeight({
    required String dogId,
    required double weight,
    String? notes,
    String? photoUrl,
    double? bodyConditionScore,
  }) async {
    try {
      final log = WeightLog(
        id: '',
        dogId: dogId,
        weight: weight,
        date: DateTime.now(),
        notes: notes,
        photoUrl: photoUrl,
        bodyConditionScore: bodyConditionScore,
      );

      final docRef = await _firestore
          .collection('weight_logs')
          .add(log.toFirestore());

      return log.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to log weight: $e');
    }
  }

  /// Get weight logs for a dog
  Future<List<WeightLog>> getWeightLogs(String dogId, {int? limit}) async {
    try {
      var query = _firestore
          .collection('weight_logs')
          .where('dogId', isEqualTo: dogId)
          .orderBy('date', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => WeightLog.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch weight logs: $e');
    }
  }

  /// Calculate progress percentage
  double calculateProgress({
    required double startWeight,
    required double currentWeight,
    required double targetWeight,
  }) {
    final totalToLose = startWeight - targetWeight;
    if (totalToLose <= 0) return 0;

    final lost = startWeight - currentWeight;
    return (lost / totalToLose * 100).clamp(0, 100);
  }

  /// Check and award milestones
  Future<List<Milestone>> checkMilestones({
    required String dogId,
    required double progressPercent,
    required int currentStreak,
    required int totalMealsLogged,
  }) async {
    final newMilestones = <Milestone>[];

    try {
      // Get existing milestones
      final existing = await getMilestones(dogId);
      final existingTypes = existing.map((m) => m.type).toSet();

      // Check weight loss milestones
      if (progressPercent >= 25 && !existingTypes.contains(MilestoneType.weightLoss25)) {
        newMilestones.add(Milestone.create(dogId: dogId, type: MilestoneType.weightLoss25));
      }
      if (progressPercent >= 50 && !existingTypes.contains(MilestoneType.weightLoss50)) {
        newMilestones.add(Milestone.create(dogId: dogId, type: MilestoneType.weightLoss50));
      }
      if (progressPercent >= 75 && !existingTypes.contains(MilestoneType.weightLoss75)) {
        newMilestones.add(Milestone.create(dogId: dogId, type: MilestoneType.weightLoss75));
      }
      if (progressPercent >= 100 && !existingTypes.contains(MilestoneType.weightLossGoal)) {
        newMilestones.add(Milestone.create(dogId: dogId, type: MilestoneType.weightLossGoal));
      }

      // Check streak milestones
      if (currentStreak >= 7 && !existingTypes.contains(MilestoneType.streak7Days)) {
        newMilestones.add(Milestone.create(dogId: dogId, type: MilestoneType.streak7Days));
      }
      if (currentStreak >= 30 && !existingTypes.contains(MilestoneType.streak30Days)) {
        newMilestones.add(Milestone.create(dogId: dogId, type: MilestoneType.streak30Days));
      }
      if (currentStreak >= 90 && !existingTypes.contains(MilestoneType.streak90Days)) {
        newMilestones.add(Milestone.create(dogId: dogId, type: MilestoneType.streak90Days));
      }

      // Check meal logging milestones
      if (totalMealsLogged == 1 && !existingTypes.contains(MilestoneType.firstMeal)) {
        newMilestones.add(Milestone.create(dogId: dogId, type: MilestoneType.firstMeal));
      }
      if (totalMealsLogged >= 100 && !existingTypes.contains(MilestoneType.hundredthMeal)) {
        newMilestones.add(Milestone.create(dogId: dogId, type: MilestoneType.hundredthMeal));
      }

      // Save new milestones to Firestore
      for (final milestone in newMilestones) {
        await _firestore.collection('milestones').add({
          'dogId': milestone.dogId,
          'type': milestone.type.name,
          'title': milestone.title,
          'description': milestone.description,
          'iconEmoji': milestone.iconEmoji,
          'achievedAt': Timestamp.fromDate(milestone.achievedAt),
          'isCelebrated': false,
        });
      }

      return newMilestones;
    } catch (e) {
      print('Error checking milestones: $e');
      return [];
    }
  }

  /// Get all milestones for a dog
  Future<List<Milestone>> getMilestones(String dogId) async {
    try {
      final snapshot = await _firestore
          .collection('milestones')
          .where('dogId', isEqualTo: dogId)
          .orderBy('achievedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Milestone(
          id: doc.id,
          dogId: data['dogId'],
          type: MilestoneType.values.firstWhere(
            (e) => e.name == data['type'],
            orElse: () => MilestoneType.firstMeal,
          ),
          title: data['title'],
          description: data['description'],
          iconEmoji: data['iconEmoji'],
          achievedAt: (data['achievedAt'] as Timestamp).toDate(),
          isCelebrated: data['isCelebrated'] ?? false,
        );
      }).toList();
    } catch (e) {
      print('Error fetching milestones: $e');
      return [];
    }
  }

  /// Mark milestone as celebrated
  Future<void> celebrateMilestone(String milestoneId) async {
    try {
      await _firestore
          .collection('milestones')
          .doc(milestoneId)
          .update({'isCelebrated': true});
    } catch (e) {
      print('Error celebrating milestone: $e');
    }
  }

  /// Calculate current streak
  Future<int> calculateStreak(String dogId) async {
    try {
      final now = DateTime.now();
      final logs = await _firestore
          .collection('meals')
          .where('dogId', isEqualTo: dogId)
          .orderBy('timestamp', descending: true)
          .get();

      if (logs.docs.isEmpty) return 0;

      var streak = 0;
      var currentDate = DateTime(now.year, now.month, now.day);

      final daysWithMeals = logs.docs.map((doc) {
        final timestamp = (doc.data()['timestamp'] as Timestamp).toDate();
        return DateTime(timestamp.year, timestamp.month, timestamp.day);
      }).toSet();

      while (daysWithMeals.contains(currentDate)) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      }

      return streak;
    } catch (e) {
      print('Error calculating streak: $e');
      return 0;
    }
  }

  /// Get weight trend (gaining, losing, maintaining)
  String getWeightTrend(List<WeightLog> logs) {
    if (logs.length < 2) return 'insufficient_data';

    final recent = logs.take(2).toList();
    final diff = recent[1].weight - recent[0].weight;

    if (diff > 0.2) return 'gaining';
    if (diff < -0.2) return 'losing';
    return 'maintaining';
  }
}
