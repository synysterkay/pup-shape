import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OneSignalService {
  static const String appId = '582318b8-bb3d-4fe5-a8a8-fb7c653290eb';
  
  static Future<void> initialize() async {
    // Initialize OneSignal
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(appId);
    
    // Request notification permissions
    await OneSignal.Notifications.requestPermission(true);
    
    // Set up notification handlers
    _setupNotificationHandlers();
  }
  
  static void _setupNotificationHandlers() {
    // Handle notification opened
    OneSignal.Notifications.addClickListener((event) {
      print('OneSignal: Notification clicked: ${event.notification.additionalData}');
      _handleNotificationAction(event.notification.additionalData);
    });
    
    // Handle notification received while app is in foreground
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      print('OneSignal: Notification received in foreground');
      event.notification.display();
    });
  }
  
  static void _handleNotificationAction(Map<String, dynamic>? data) {
    if (data == null) return;
    
    // Handle different notification types with deep linking
    final String? type = data['type'];
    switch (type) {
      case 'meal_reminder':
        // Navigate to meal logging screen
        break;
      case 'weigh_in':
        // Navigate to weight tracking
        break;
      case 'milestone':
        // Show achievement dialog
        break;
      case 'ai_chat':
        // Open AI chat
        break;
    }
  }
  
  /// Set user ID to sync with Firebase
  static Future<void> setUserId(String userId) async {
    await OneSignal.login(userId);
    print('OneSignal: User logged in with ID: $userId');
  }
  
  /// Set user tags for segmentation
  static Future<void> setUserTags({
    required String dogName,
    required String dogBreed,
    required double currentWeight,
    required double targetWeight,
    required String activityLevel,
    required int daysSinceStart,
  }) async {
    await OneSignal.User.addTags({
      'dog_name': dogName,
      'dog_breed': dogBreed,
      'current_weight': currentWeight.toString(),
      'target_weight': targetWeight.toString(),
      'activity_level': activityLevel,
      'days_since_start': daysSinceStart.toString(),
      'weight_to_lose': (currentWeight - targetWeight).toStringAsFixed(1),
    });
    print('OneSignal: User tags set');
  }
  
  /// Set email for email campaigns
  static Future<void> setEmail(String email) async {
    await OneSignal.User.addEmail(email);
    print('OneSignal: Email set: $email');
  }
  
  /// Track custom events for automation triggers
  static void trackEvent(String eventName, {Map<String, dynamic>? properties}) {
    // OneSignal.Session.addOutcome(eventName);
    print('OneSignal: Event tracked: $eventName');
  }
  
  /// Log out user from OneSignal
  static Future<void> logout() async {
    await OneSignal.logout();
    print('OneSignal: User logged out');
  }
  
  /// Update last activity timestamp
  static Future<void> updateLastActivity() async {
    await OneSignal.User.addTags({
      'last_active': DateTime.now().toIso8601String(),
    });
  }
  
  /// Set meal reminder times
  static Future<void> setMealReminderTimes(int breakfastHour, int dinnerHour) async {
    await OneSignal.User.addTags({
      'breakfast_hour': breakfastHour.toString(),
      'dinner_hour': dinnerHour.toString(),
    });
  }
  
  /// Mark milestone achievement
  static Future<void> trackMilestone(String milestoneType, double value) async {
    await OneSignal.User.addTags({
      'milestone_$milestoneType': value.toString(),
      'last_milestone': DateTime.now().toIso8601String(),
    });
    trackEvent('milestone_achieved', properties: {
      'type': milestoneType,
      'value': value,
    });
  }
  
  /// Track subscription status
  static Future<void> setSubscriptionStatus(bool isPremium) async {
    await OneSignal.User.addTags({
      'is_premium': isPremium ? 'true' : 'false',
    });
  }
}
