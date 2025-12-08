import 'package:cloud_firestore/cloud_firestore.dart';

class Meal {
  final String id;
  final String dogId;
  final String foodName;
  final String brand;
  final double portionSize; // in grams
  final double quantity; // in grams (alias for portionSize)
  final double calories;
  final String mealType; // breakfast, lunch, dinner, snack, treat
  final Map<String, dynamic> nutritionalInfo;
  final String barcode;
  final DateTime mealTime;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Meal({
    required this.id,
    required this.dogId,
    required this.foodName,
    this.brand = '',
    required this.portionSize,
    required this.calories,
    this.mealType = 'breakfast',
    this.nutritionalInfo = const {},
    this.barcode = '',
    required this.mealTime,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  }) : quantity = portionSize; // quantity is an alias for portionSize

  factory Meal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Meal(
      id: doc.id,
      dogId: data['dogId'] ?? '',
      foodName: data['foodName'] ?? '',
      brand: data['brand'] ?? '',
      portionSize: (data['portionSize'] ?? 0.0).toDouble(),
      calories: (data['calories'] ?? 0.0).toDouble(),
      mealType: data['mealType'] ?? 'breakfast',
      nutritionalInfo: Map<String, dynamic>.from(data['nutritionalInfo'] ?? {}),
      barcode: data['barcode'] ?? '',
      mealTime: (data['mealTime'] as Timestamp).toDate(),
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'dogId': dogId,
      'foodName': foodName,
      'brand': brand,
      'portionSize': portionSize,
      'calories': calories,
      'mealType': mealType,
      'nutritionalInfo': nutritionalInfo,
      'barcode': barcode,
      'mealTime': Timestamp.fromDate(mealTime),
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Meal copyWith({
    String? foodName,
    String? brand,
    double? portionSize,
    double? calories,
    String? mealType,
    Map<String, dynamic>? nutritionalInfo,
    String? barcode,
    DateTime? mealTime,
    String? notes,
    DateTime? updatedAt,
  }) {
    return Meal(
      id: id,
      dogId: dogId,
      foodName: foodName ?? this.foodName,
      brand: brand ?? this.brand,
      portionSize: portionSize ?? this.portionSize,
      calories: calories ?? this.calories,
      mealType: mealType ?? this.mealType,
      nutritionalInfo: nutritionalInfo ?? this.nutritionalInfo,
      barcode: barcode ?? this.barcode,
      mealTime: mealTime ?? this.mealTime,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
