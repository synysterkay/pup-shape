import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pupshape/models/dog.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Notification IDs
  static const int _mealReminderBaseId = 1000;
  static const int _missedMealBaseId = 2000;
  static const int _dailySummaryId = 3000;
  static const int _streakCelebrationId = 4000;
  static const int _progressAlertId = 5000;
  static const int _hydrationReminderId = 6000;
  static const int _activityPromptId = 7000;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();
      
      // Android initialization
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = true;
      print('NotificationService initialized successfully');
    } catch (e) {
      print('Error initializing NotificationService: $e');
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    try {
      // Request notification permission
      final status = await Permission.notification.request();
      
      if (status.isGranted) {
        print('Notification permission granted');
        return true;
      } else {
        print('Notification permission denied');
        return false;
      }
    } catch (e) {
      print('Error requesting notification permissions: $e');
      return false;
    }
  }

  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;
    
    try {
      final status = await Permission.notification.status;
      return status.isGranted;
    } catch (e) {
      print('Error checking notification status: $e');
      return false;
    }
  }

  // Schedule meal reminders for a dog
  Future<void> scheduleMealReminders(Dog dog) async {
    if (!_isInitialized || !dog.enableMealReminders) return;

    try {
      // Cancel existing reminders for this dog
      await cancelMealReminders(dog.id);

      final now = DateTime.now();
      
      for (final entry in dog.mealSchedule.entries) {
        final mealType = entry.key;
        final timeMap = entry.value;
        final mealTime = TimeOfDay(hour: timeMap['hour']!, minute: timeMap['minute']!);
        
        // Schedule reminder notification
        await _scheduleMealReminder(
          dog: dog,
          mealType: mealType,
          mealTime: mealTime,
          reminderMinutes: dog.reminderMinutesBefore,
        );
        
        // Schedule missed meal notification
        await _scheduleMissedMealAlert(
          dog: dog,
          mealType: mealType,
          mealTime: mealTime,
        );
      }
      
      print('Scheduled meal reminders for ${dog.name}');
    } catch (e) {
      print('Error scheduling meal reminders: $e');
    }
  }

  Future<void> _scheduleMealReminder({
    required Dog dog,
    required String mealType,
    required TimeOfDay mealTime,
    required int reminderMinutes,
  }) async {
    final now = DateTime.now();
    final reminderTime = DateTime(
      now.year,
      now.month,
      now.day,
      mealTime.hour,
      mealTime.minute,
    ).subtract(Duration(minutes: reminderMinutes));

    // If reminder time has passed today, schedule for tomorrow
    DateTime scheduledTime = reminderTime.isBefore(now) 
        ? reminderTime.add(const Duration(days: 1))
        : reminderTime;

    final notificationId = _mealReminderBaseId + dog.id.hashCode + mealType.hashCode;

    await _notifications.zonedSchedule(
      notificationId,
      '🍽️ Time to feed ${dog.name}!',
      '${mealType.toUpperCase()} is coming up in $reminderMinutes minutes',
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'meal_reminders',
          'Meal Reminders',
          channelDescription: 'Notifications to remind you to feed your dog',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF6366F1),
          actions: [
            const AndroidNotificationAction(
              'log_meal',
              'Log Meal',
              showsUserInterface: true,
            ),
            const AndroidNotificationAction(
              'snooze',
              'Remind Later',
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'meal_reminder',
          threadIdentifier: 'meal_${dog.id}',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'meal_reminder|${dog.id}|$mealType',
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleMissedMealAlert({
    required Dog dog,
    required String mealType,
    required TimeOfDay mealTime,
  }) async {
    final now = DateTime.now();
    final alertTime = DateTime(
      now.year,
      now.month,
      now.day,
      mealTime.hour,
      mealTime.minute,
    ).add(const Duration(hours: 2)); // 2 hours after meal time

    // If alert time has passed today, schedule for tomorrow
    DateTime scheduledTime = alertTime.isBefore(now) 
        ? alertTime.add(const Duration(days: 1))
        : alertTime;

    final notificationId = _missedMealBaseId + dog.id.hashCode + mealType.hashCode;

    await _notifications.zonedSchedule(
      notificationId,
      '⚠️ Missed meal for ${dog.name}?',
      'Haven\'t logged ${dog.name}\'s ${mealType.toUpperCase()} yet. Everything okay?',
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'missed_meals',
          'Missed Meal Alerts',
          channelDescription: 'Alerts when meals haven\'t been logged',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Colors.orange,
          actions: [
            const AndroidNotificationAction(
              'log_meal',
              'Log Now',
              showsUserInterface: true,
            ),
            const AndroidNotificationAction(
              'dismiss',
              'Dismiss',
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'missed_meal',
          threadIdentifier: 'missed_${dog.id}',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'missed_meal|${dog.id}|$mealType',
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Schedule daily summary notification
  Future<void> scheduleDailySummary(String dogId, String dogName, TimeOfDay summaryTime) async {
    if (!_isInitialized) return;

    try {
      final now = DateTime.now();
      final scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        summaryTime.hour,
        summaryTime.minute,
      );

      // If time has passed today, schedule for tomorrow
      final finalTime = scheduledTime.isBefore(now) 
          ? scheduledTime.add(const Duration(days: 1))
          : scheduledTime;

      await _notifications.zonedSchedule(
        _dailySummaryId + dogId.hashCode,
        '📊 Daily Summary for $dogName',
        'Check how $dogName did today with nutrition and activity',
        tz.TZDateTime.from(finalTime, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_summary',
            'Daily Summary',
            channelDescription: 'Daily nutrition and activity summaries',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
            color: const Color(0xFF6366F1),
          ),
          iOS: DarwinNotificationDetails(
            categoryIdentifier: 'daily_summary',
            threadIdentifier: 'summary_$dogId',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'daily_summary|$dogId',
        matchDateTimeComponents: DateTimeComponents.time,
      );

      print('Scheduled daily summary for $dogName');
    } catch (e) {
      print('Error scheduling daily summary: $e');
    }
  }

  // Cancel meal reminders for a specific dog
  Future<void> cancelMealReminders(String dogId) async {
    if (!_isInitialized) return;

    try {
      final pendingNotifications = await _notifications.pendingNotificationRequests();
      
      for (final notification in pendingNotifications) {
        if (notification.payload?.contains(dogId) == true) {
          await _notifications.cancel(notification.id);
        }
      }
      
      print('Cancelled meal reminders for dog: $dogId');
    } catch (e) {
      print('Error cancelling meal reminders: $e');
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;

    try {
      await _notifications.cancelAll();
      print('Cancelled all notifications');
    } catch (e) {
      print('Error cancelling all notifications: $e');
    }
  }

  // Show immediate notification (for testing)
  Future<void> showTestNotification() async {
    if (!_isInitialized) return;

    try {
      await _notifications.show(
        999,
        '🐕 Test Notification',
        'PupShape notifications are working!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test',
            'Test Notifications',
            channelDescription: 'Test notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFF6366F1),
          ),
          iOS: DarwinNotificationDetails(
            categoryIdentifier: 'test',
          ),
        ),
        payload: 'test_notification',
      );
    } catch (e) {
      print('Error showing test notification: $e');
    }
  }

  // Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_isInitialized) return [];
    
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      print('Error getting pending notifications: $e');
      return [];
    }
  }

  // Show streak celebration notification
  Future<void> showStreakCelebration(String dogId, String dogName, int streakDays) async {
    if (!_isInitialized) return;

    try {
      await _notifications.show(
        _streakCelebrationId + dogId.hashCode,
        '🔥 $streakDays Day Streak!',
        'Amazing! $dogName has been tracked for $streakDays days in a row. Keep it going!',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'streak',
            'Streak Celebrations',
            channelDescription: 'Celebrate logging streaks',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Colors.orange,
          ),
          iOS: DarwinNotificationDetails(
            categoryIdentifier: 'streak',
            threadIdentifier: 'streak_$dogId',
          ),
        ),
        payload: 'streak|$dogId|$streakDays',
      );
    } catch (e) {
      print('Error showing streak celebration: $e');
    }
  }

  // Show progress alert
  Future<void> showProgressAlert(String dogId, String dogName, String message) async {
    if (!_isInitialized) return;

    try {
      await _notifications.show(
        _progressAlertId + dogId.hashCode,
        '🎉 Progress Update for $dogName',
        message,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'progress',
            'Progress Alerts',
            channelDescription: 'Weight loss progress notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Colors.green,
          ),
          iOS: DarwinNotificationDetails(
            categoryIdentifier: 'progress',
            threadIdentifier: 'progress_$dogId',
          ),
        ),
        payload: 'progress|$dogId',
      );
    } catch (e) {
      print('Error showing progress alert: $e');
    }
  }

  // Schedule hydration reminders
  Future<void> scheduleHydrationReminders(String dogId, String dogName) async {
    if (!_isInitialized) return;

    try {
      // Schedule 3 hydration reminders throughout the day
      final times = [
        const TimeOfDay(hour: 10, minute: 0),
        const TimeOfDay(hour: 14, minute: 0),
        const TimeOfDay(hour: 18, minute: 0),
      ];

      for (var i = 0; i < times.length; i++) {
        final time = times[i];
        final now = DateTime.now();
        var scheduledTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
        
        if (scheduledTime.isBefore(now)) {
          scheduledTime = scheduledTime.add(const Duration(days: 1));
        }

        await _notifications.zonedSchedule(
          _hydrationReminderId + dogId.hashCode + i,
          '💧 Water Check for $dogName',
          'Make sure $dogName has fresh water available!',
          tz.TZDateTime.from(scheduledTime, tz.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              'hydration',
              'Hydration Reminders',
              channelDescription: 'Reminders to check water',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
              icon: '@mipmap/ic_launcher',
              color: Colors.blue,
            ),
            iOS: DarwinNotificationDetails(
              categoryIdentifier: 'hydration',
              threadIdentifier: 'hydration_$dogId',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'hydration|$dogId',
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }

      print('Scheduled hydration reminders for $dogName');
    } catch (e) {
      print('Error scheduling hydration reminders: $e');
    }
  }

  // Schedule activity prompts
  Future<void> scheduleActivityPrompts(String dogId, String dogName) async {
    if (!_isInitialized) return;

    try {
      // Schedule morning and evening activity prompts
      final times = [
        const TimeOfDay(hour: 8, minute: 0),
        const TimeOfDay(hour: 17, minute: 0),
      ];

      final messages = [
        'Morning walk time! Start the day with some exercise for $dogName.',
        'Evening activity! $dogName would love a walk or play session.',
      ];

      for (var i = 0; i < times.length; i++) {
        final time = times[i];
        final now = DateTime.now();
        var scheduledTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
        
        if (scheduledTime.isBefore(now)) {
          scheduledTime = scheduledTime.add(const Duration(days: 1));
        }

        await _notifications.zonedSchedule(
          _activityPromptId + dogId.hashCode + i,
          '🏃 Activity Time!',
          messages[i],
          tz.TZDateTime.from(scheduledTime, tz.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              'activity',
              'Activity Prompts',
              channelDescription: 'Exercise and activity reminders',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
              icon: '@mipmap/ic_launcher',
              color: Colors.green,
            ),
            iOS: DarwinNotificationDetails(
              categoryIdentifier: 'activity',
              threadIdentifier: 'activity_$dogId',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'activity|$dogId',
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }

      print('Scheduled activity prompts for $dogName');
    } catch (e) {
      print('Error scheduling activity prompts: $e');
    }
  }

  // Handle notification taps
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    print('Notification tapped with payload: $payload');
    
    final parts = payload.split('|');
    if (parts.length < 2) return;

    final type = parts[0];
    final dogId = parts[1];
    
    switch (type) {
      case 'meal_reminder':
      case 'missed_meal':
        // Navigate to meal logging screen
        // This would need to be handled by the main app navigation
        print('Should navigate to meal logging for dog: $dogId');
        break;
      case 'daily_summary':
        // Navigate to daily summary
        print('Should navigate to daily summary for dog: $dogId');
        break;
      case 'streak':
        print('Should show streak celebration screen for dog: $dogId');
        break;
      case 'progress':
        print('Should navigate to progress screen for dog: $dogId');
        break;
      case 'hydration':
      case 'activity':
        print('Reminder acknowledged for dog: $dogId');
        break;
    }
  }
}
