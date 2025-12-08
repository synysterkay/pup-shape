import 'package:cloud_firestore/cloud_firestore.dart';

class WeightLog {
  final String id;
  final String dogId;
  final double weight; // in kg
  final DateTime date;
  final String? notes;
  final String? photoUrl;
  final double? bodyConditionScore; // 1-9 scale

  WeightLog({
    required this.id,
    required this.dogId,
    required this.weight,
    required this.date,
    this.notes,
    this.photoUrl,
    this.bodyConditionScore,
  });

  factory WeightLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WeightLog(
      id: doc.id,
      dogId: data['dogId'] ?? '',
      weight: (data['weight'] ?? 0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      notes: data['notes'],
      photoUrl: data['photoUrl'],
      bodyConditionScore: data['bodyConditionScore']?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'dogId': dogId,
      'weight': weight,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'photoUrl': photoUrl,
      'bodyConditionScore': bodyConditionScore,
    };
  }

  WeightLog copyWith({
    String? id,
    String? dogId,
    double? weight,
    DateTime? date,
    String? notes,
    String? photoUrl,
    double? bodyConditionScore,
  }) {
    return WeightLog(
      id: id ?? this.id,
      dogId: dogId ?? this.dogId,
      weight: weight ?? this.weight,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
      bodyConditionScore: bodyConditionScore ?? this.bodyConditionScore,
    );
  }
}
