import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pupshape/models/progress_photo.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

class ProgressPhotoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a progress photo to Firebase Storage and save metadata to Firestore
  Future<ProgressPhoto> uploadProgressPhoto({
    required String dogId,
    required XFile imageFile,
    double? weight,
    String? notes,
  }) async {
    try {
      final now = DateTime.now();
      final fileName = 'progress_${dogId}_${now.millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('progress_photos/$dogId/$fileName');

      // Upload image
      String downloadUrl;
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        await ref.putData(bytes);
        downloadUrl = await ref.getDownloadURL();
      } else {
        final file = File(imageFile.path);
        await ref.putFile(file);
        downloadUrl = await ref.getDownloadURL();
      }

      // Create photo document
      final photo = ProgressPhoto(
        id: '',
        dogId: dogId,
        imageUrl: downloadUrl,
        date: now,
        weight: weight,
        notes: notes,
        createdAt: now,
      );

      // Save to Firestore
      final docRef = await _firestore
          .collection('progress_photos')
          .add(photo.toFirestore());

      return photo.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to upload progress photo: $e');
    }
  }

  /// Get all progress photos for a dog
  Future<List<ProgressPhoto>> getProgressPhotos(String dogId) async {
    try {
      final querySnapshot = await _firestore
          .collection('progress_photos')
          .where('dogId', isEqualTo: dogId)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ProgressPhoto.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch progress photos: $e');
    }
  }

  /// Delete a progress photo
  Future<void> deleteProgressPhoto(String photoId, String imageUrl) async {
    try {
      // Delete from Storage
      try {
        final ref = _storage.refFromURL(imageUrl);
        await ref.delete();
      } catch (e) {
        print('Warning: Could not delete image from storage: $e');
      }

      // Delete from Firestore
      await _firestore.collection('progress_photos').doc(photoId).delete();
    } catch (e) {
      throw Exception('Failed to delete progress photo: $e');
    }
  }

  /// Get photos for comparison (first and latest)
  Future<Map<String, ProgressPhoto?>> getComparisonPhotos(String dogId) async {
    try {
      final photos = await getProgressPhotos(dogId);
      
      if (photos.isEmpty) {
        return {'first': null, 'latest': null};
      }

      return {
        'first': photos.last, // Oldest (list is sorted desc)
        'latest': photos.first, // Latest
      };
    } catch (e) {
      throw Exception('Failed to fetch comparison photos: $e');
    }
  }

  /// Update photo notes or weight
  Future<void> updateProgressPhoto({
    required String photoId,
    double? weight,
    String? notes,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (weight != null) updates['weight'] = weight;
      if (notes != null) updates['notes'] = notes;

      await _firestore
          .collection('progress_photos')
          .doc(photoId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update progress photo: $e');
    }
  }
}
