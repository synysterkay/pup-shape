import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pupshape/config/theme.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  void _handleStartJourney(BuildContext context) async {
    if (kIsWeb) {
      // On web, bypass paywall and go directly to assessment
      Navigator.of(context).pushReplacementNamed('/assessment');
    } else {
      // On mobile (Android & iOS), show Superwall paywall
      try {
        // Register placement to potentially show paywall
        await Superwall.shared.registerPlacement('campaign_trigger',
          feature: () {
            // Feature block - executed if paywall is not shown or user has access
            Navigator.of(context).pushReplacementNamed('/assessment');
          }
        );
      } catch (e) {
        print('Error showing Superwall: $e');
        // Fallback to direct navigation if Superwall fails
        Navigator.of(context).pushReplacementNamed('/assessment');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
              
              // Logo/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.pets,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Main Headline
              const Text(
                'Welcome to PupShape',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Subheadline
              Text(
                'AI-Powered Weight Management\nFor Your Dog',
                style: TextStyle(
                  fontSize: 18,
                  color: AppTheme.textSecondaryColor,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Feature List
              _buildFeature(
                icon: Icons.calendar_today,
                title: '12-Week Personalized Plan',
                description: 'AI creates a custom weight loss journey',
              ),
              
              const SizedBox(height: 20),
              
              _buildFeature(
                icon: Icons.restaurant_menu,
                title: 'Daily Meal Plans',
                description: 'Know exactly what to feed every day',
              ),
              
              const SizedBox(height: 20),
              
              _buildFeature(
                icon: Icons.qr_code_scanner,
                title: 'Smart Food Scanner',
                description: 'Grade any dog food with AI (A-F)',
              ),
              
              const SizedBox(height: 20),
              
              _buildFeature(
                icon: Icons.chat_bubble_outline,
                title: 'AI Nutritionist Chat',
                description: 'Ask questions anytime, get instant answers',
              ),
              
              const SizedBox(height: 48),
              
              // CTA Button - Triggers Superwall
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _handleStartJourney(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: AppTheme.primaryColor.withOpacity(0.4),
                  ),
                  child: const Text(
                    'Start Your Journey',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeature({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
