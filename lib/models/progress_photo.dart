import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressPhoto {
  final String id;
  final String dogId;
  final String imageUrl;
  final DateTime date;
  final double? weight;
  final String? notes;
  final DateTime createdAt;

  ProgressPhoto({
    required this.id,
    required this.dogId,
    required this.imageUrl,
    required this.date,
    this.weight,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'dogId': dogId,
      'imageUrl': imageUrl,
      'date': Timestamp.fromDate(date),
      'weight': weight,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ProgressPhoto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProgressPhoto(
      id: doc.id,
      dogId: data['dogId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      weight: data['weight']?.toDouble(),
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  ProgressPhoto copyWith({
    String? id,
    String? dogId,
    String? imageUrl,
    DateTime? date,
    double? weight,
    String? notes,
    DateTime? createdAt,
  }) {
    return ProgressPhoto(
      id: id ?? this.id,
      dogId: dogId ?? this.dogId,
      imageUrl: imageUrl ?? this.imageUrl,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
