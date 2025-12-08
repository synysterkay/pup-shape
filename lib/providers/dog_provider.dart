import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pupshape/models/dog.dart';
import 'package:pupshape/services/notification_service.dart';
import 'package:pupshape/services/onesignal_service.dart';

class DogProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  List<Dog> _dogs = [];
  Dog? _selectedDog;
  bool _isLoading = false;
  String _errorMessage = '';

  List<Dog> get dogs => _dogs;
  Dog? get selectedDog => _selectedDog;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  DogProvider() {
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    if (!kIsWeb) {
      try {
        await _notificationService.initialize();
        await _notificationService.requestPermissions();
        print('✅ Notification service initialized in DogProvider');
      } catch (e) {
        print('⚠️ Failed to initialize notifications: $e');
      }
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  Future<void> fetchDogs() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ No authenticated user found');
      return;
    }

    try {
      _setLoading(true);
      _setError('');

      print('🐕 Fetching dogs for user: ${user.email}');

      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('dogs')
          .orderBy('createdAt', descending: false)
          .get();

      _dogs = querySnapshot.docs.map((doc) => Dog.fromFirestore(doc)).toList();
      
      print('✅ Fetched ${_dogs.length} dogs');

      // Auto-select first dog if none selected and dogs exist
      if (_dogs.isNotEmpty && _selectedDog == null) {
        _selectedDog = _dogs.first;
        print('🎯 Auto-selected dog: ${_selectedDog!.name}');
      }

      // Schedule notifications for all dogs (only on mobile)
      if (!kIsWeb) {
        await _scheduleNotificationsForAllDogs();
      }

      _setLoading(false);
    } catch (e) {
      print('❌ Error fetching dogs: $e');
      _setError('Failed to load dogs: $e');
      _setLoading(false);
    }
  }

  Future<void> _scheduleNotificationsForAllDogs() async {
    try {
      for (final dog in _dogs) {
        if (dog.enableMealReminders) {
          await _notificationService.scheduleMealReminders(dog);
          print('📅 Scheduled notifications for ${dog.name}');
        }
      }
    } catch (e) {
      print('⚠️ Error scheduling notifications: $e');
    }
  }

  Future<void> addDog(Dog dog) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ No authenticated user found');
      return;
    }

    try {
      _setLoading(true);
      _setError('');

      print('➕ Adding new dog: ${dog.name}');

      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('dogs')
          .add(dog.toFirestore());

      final dogWithId = dog.copyWith(id: docRef.id);
      _dogs.add(dogWithId);
      
      // Auto-select if it's the first dog
      if (_dogs.length == 1) {
        _selectedDog = dogWithId;
        print('🎯 Auto-selected first dog: ${dogWithId.name}');
      }

      // Schedule notifications for the new dog (only on mobile)
      if (!kIsWeb && dogWithId.enableMealReminders) {
        await _notificationService.scheduleMealReminders(dogWithId);
        print('📅 Scheduled notifications for new dog: ${dogWithId.name}');
      }
      
      // Sync with OneSignal (only on mobile)
      if (!kIsWeb) {
        try {
          await OneSignalService.setUserTags(
            dogName: dogWithId.name,
            dogBreed: dogWithId.breed,
            currentWeight: dogWithId.weight,
            targetWeight: dogWithId.targetWeight ?? dogWithId.weight,
            activityLevel: dogWithId.activityLevel,
            daysSinceStart: DateTime.now().difference(dogWithId.createdAt).inDays,
          );
          
          // Set meal reminder times
          final breakfast = dogWithId.mealSchedule['breakfast'] as Map<String, dynamic>?;
          final dinner = dogWithId.mealSchedule['dinner'] as Map<String, dynamic>?;
          if (breakfast != null && dinner != null) {
            await OneSignalService.setMealReminderTimes(
              breakfast['hour'] as int,
              dinner['hour'] as int,
            );
          }
          print('📲 Synced dog data with OneSignal');
        } catch (e) {
          print('⚠️ Failed to sync with OneSignal: $e');
        }
      }

      print('✅ Successfully added dog: ${dogWithId.name}');
      _setLoading(false);
    } catch (e) {
      print('❌ Error adding dog: $e');
      _setError('Failed to add dog: $e');
      _setLoading(false);
    }
  }

  Future<void> updateDog(Dog dog) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ No authenticated user found');
      return;
    }

    try {
      _setLoading(true);
      _setError('');

      print('✏️ Updating dog: ${dog.name}');

      final updatedDog = dog.copyWith(updatedAt: DateTime.now());

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('dogs')
          .doc(dog.id)
          .update(updatedDog.toFirestore());

      final index = _dogs.indexWhere((d) => d.id == dog.id);
      if (index != -1) {
        _dogs[index] = updatedDog;
        
        // Update selected dog if it's the same one
        if (_selectedDog?.id == dog.id) {
          _selectedDog = updatedDog;
        }
      }

      // Update notifications for the dog (only on mobile)
      if (!kIsWeb) {
        if (updatedDog.enableMealReminders) {
          await _notificationService.scheduleMealReminders(updatedDog);
          print('📅 Updated notifications for ${updatedDog.name}');
        } else {
          await _notificationService.cancelMealReminders(updatedDog.id);
          print('🔕 Cancelled notifications for ${updatedDog.name}');
        }
      }

      print('✅ Successfully updated dog: ${updatedDog.name}');
      _setLoading(false);
    } catch (e) {
      print('❌ Error updating dog: $e');
      _setError('Failed to update dog: $e');
      _setLoading(false);
    }
  }

  Future<void> deleteDog(String dogId) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ No authenticated user found');
      return;
    }

    try {
      _setLoading(true);
      _setError('');

      print('🗑️ Deleting dog with ID: $dogId');

      // Find the dog to delete
      final dogToDelete = _dogs.firstWhere((d) => d.id == dogId);

      // Cancel notifications for this dog first (only on mobile)
      if (!kIsWeb) {
        await _notificationService.cancelMealReminders(dogId);
        print('🔕 Cancelled notifications for dog: ${dogToDelete.name}');
      }

      // Delete from Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('dogs')
          .doc(dogId)
          .delete();

      // Remove from local list
      _dogs.removeWhere((d) => d.id == dogId);

      // Update selected dog if it was the deleted one
      if (_selectedDog?.id == dogId) {
        _selectedDog = _dogs.isNotEmpty ? _dogs.first : null;
        print('🎯 Selected new dog: ${_selectedDog?.name ?? 'none'}');
      }

      print('✅ Successfully deleted dog: ${dogToDelete.name}');
      _setLoading(false);
    } catch (e) {
      print('❌ Error deleting dog: $e');
      _setError('Failed to delete dog: $e');
      _setLoading(false);
    }
  }

  void selectDog(Dog dog) {
    if (_selectedDog?.id != dog.id) {
      _selectedDog = dog;
      print('🎯 Selected dog: ${dog.name}');
      notifyListeners();
    }
  }

  Future<void> setActiveDog(Dog dog) async {
    selectDog(dog);
  }

  Dog? getDogById(String dogId) {
    try {
      return _dogs.firstWhere((d) => d.id == dogId);
    } catch (e) {
      print('⚠️ Dog not found with ID: $dogId');
      return null;
    }
  }

  List<Dog> getDogsByIds(List<String> dogIds) {
    return _dogs.where((dog) => dogIds.contains(dog.id)).toList();
  }

  bool hasDogs() {
    return _dogs.isNotEmpty;
  }

  void clear() {
    _dogs.clear();
    _selectedDog = null;
    _errorMessage = '';
    _isLoading = false;
    print('🧹 Cleared all dog data');
    notifyListeners();
  }

  // Get dogs with meal reminders enabled
  List<Dog> getDogsWithReminders() {
    return _dogs.where((dog) => dog.enableMealReminders).toList();
  }

  // Update meal schedule for a specific dog
  Future<void> updateMealSchedule(String dogId, Map<String, Map<String, int>> newSchedule) async {
    final dog = getDogById(dogId);
    if (dog == null) {
      print('⚠️ Cannot update meal schedule - dog not found: $dogId');
      return;
    }

    final updatedDog = dog.copyWith(
      mealSchedule: newSchedule,
      updatedAt: DateTime.now(),
    );

    await updateDog(updatedDog);
  }

  // Toggle meal reminders for a specific dog
  Future<void> toggleMealReminders(String dogId, bool enabled) async {
    final dog = getDogById(dogId);
    if (dog == null) {
      print('⚠️ Cannot toggle meal reminders - dog not found: $dogId');
      return;
    }

    final updatedDog = dog.copyWith(
      enableMealReminders: enabled,
      updatedAt: DateTime.now(),
    );

    await updateDog(updatedDog);
  }

  // Update reminder timing for a specific dog
  Future<void> updateReminderTiming(String dogId, int minutesBefore) async {
    final dog = getDogById(dogId);
    if (dog == null) {
      print('⚠️ Cannot update reminder timing - dog not found: $dogId');
      return;
    }

    final updatedDog = dog.copyWith(
      reminderMinutesBefore: minutesBefore,
      updatedAt: DateTime.now(),
    );

    await updateDog(updatedDog);
  }

  // Get total daily caloric needs for all dogs
  double getTotalDailyCaloricNeeds() {
    return _dogs.fold(0.0, (total, dog) => total + dog.dailyCaloricNeeds);
  }

  // Get dogs by activity level
  List<Dog> getDogsByActivityLevel(String activityLevel) {
    return _dogs.where((dog) => dog.activityLevel == activityLevel).toList();
  }

  // Get dogs with health conditions
  List<Dog> getDogsWithHealthConditions() {
    return _dogs.where((dog) => dog.healthConditions.isNotEmpty).toList();
  }

  // Get dogs with allergies
  List<Dog> getDogsWithAllergies() {
    return _dogs.where((dog) => dog.allergies.isNotEmpty).toList();
  }

  // Search dogs by name
  List<Dog> searchDogs(String query) {
    if (query.isEmpty) return _dogs;
    
    return _dogs.where((dog) => 
      dog.name.toLowerCase().contains(query.toLowerCase()) ||
      dog.breed.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}
