import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> uploadDogImage(File imageFile, String dogId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final fileName = 'dog_${dogId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage
          .ref()
          .child('users')
          .child(user.uid)
          .child('dogs')
          .child(fileName);

      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading dog image: $e');
      return null;
    }
  }

  Future<String?> uploadUserProfileImage(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage
          .ref()
          .child('users')
          .child(user.uid)
          .child('profile')
          .child(fileName);

      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  Future<bool> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }
}
