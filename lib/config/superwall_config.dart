import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Superwall configuration and API keys
class SuperwallConfig {
  // API Keys
  static const String iosKey = 'pk_ZfnAw6GKKacCVyebj2wls';
  static const String androidKey = 'pk_Hz5P_K1_-85NbshijzF0D';
  
  // Campaign/Event Names
  static const String campaignTrigger = 'campaign_trigger';
  
  /// Get the appropriate API key for current platform
  static String getApiKey() {
    if (kIsWeb) return iosKey; // Default to iOS for web
    return Platform.isIOS ? iosKey : androidKey;
  }
  
  /// Pricing
  static const double monthlyPrice = 14.99;
  static const double yearlyPrice = 119.99;
  
  static double get yearlySavings => (monthlyPrice * 12) - yearlyPrice;
  static int get savingsPercent => ((yearlySavings / (monthlyPrice * 12)) * 100).round();
}
