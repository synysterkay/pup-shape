import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class WebAuthService {
  static Future<UserCredential?> handleGoogleSignInRedirect() async {
    if (!kIsWeb) return null;
    
    try {
      print('Checking for redirect result...');
      
      // Check if there's a pending redirect result
      final result = await FirebaseAuth.instance.getRedirectResult();
      
      // Only return result if user is present and it's not an empty result
      if (result.user != null) {
        print('Redirect result found for user: ${result.user!.email}');
        print('Is new user: ${result.additionalUserInfo?.isNewUser}');
        return result;
      } else {
        print('No redirect result or empty result');
        return null;
      }
    } catch (e) {
      print('Error handling redirect result: $e');
      return null;
    }
  }
  
  static Future<bool> isRedirectPending() async {
    if (!kIsWeb) return false;
    
    try {
      final result = await FirebaseAuth.instance.getRedirectResult();
      return result.user != null;
    } catch (e) {
      print('Error checking redirect status: $e');
      return false;
    }
  }
}
