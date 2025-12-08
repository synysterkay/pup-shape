import 'package:cloud_firestore/cloud_firestore.dart';

class DailyTip {
  final String id;
  final String dogId;
  final String title;
  final String content;
  final String category; // 'motivation', 'nutrition', 'exercise', 'health', 'breed'
  final DateTime date;
  final bool isRead;
  final String? iconEmoji;

  DailyTip({
    required this.id,
    required this.dogId,
    required this.title,
    required this.content,
    required this.category,
    required this.date,
    this.isRead = false,
    this.iconEmoji,
  });

  factory DailyTip.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyTip(
      id: doc.id,
      dogId: data['dogId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      category: data['category'] ?? 'motivation',
      date: (data['date'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      iconEmoji: data['iconEmoji'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'dogId': dogId,
      'title': title,
      'content': content,
      'category': category,
      'date': Timestamp.fromDate(date),
      'isRead': isRead,
      'iconEmoji': iconEmoji,
    };
  }

  DailyTip copyWith({
    String? id,
    String? dogId,
    String? title,
    String? content,
    String? category,
    DateTime? date,
    bool? isRead,
    String? iconEmoji,
  }) {
    return DailyTip(
      id: id ?? this.id,
      dogId: dogId ?? this.dogId,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      date: date ?? this.date,
      isRead: isRead ?? this.isRead,
      iconEmoji: iconEmoji ?? this.iconEmoji,
    );
  }

  String getCategoryIcon() {
    switch (category) {
      case 'motivation':
        return iconEmoji ?? '💪';
      case 'nutrition':
        return iconEmoji ?? '🥗';
      case 'exercise':
        return iconEmoji ?? '🏃';
      case 'health':
        return iconEmoji ?? '❤️';
      case 'breed':
        return iconEmoji ?? '🐕';
      default:
        return iconEmoji ?? '💡';
    }
  }
}
