import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:pupshape/providers/auth_provider.dart';
import 'package:pupshape/services/notification_service.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  
  const WelcomeScreen({
    super.key,
    this.onComplete,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isRequestingPermission = false;
  bool _permissionGranted = false;
  bool _showNotificationStep = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
    
    // Show notification step after animation completes (only on mobile)
    if (!kIsWeb) {
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          setState(() {
            _showNotificationStep = true;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
              Color(0xFFEC4899),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Expanded(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // App Logo
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
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
                              
                              const SizedBox(height: 32),
                              
                              // Welcome Text
                              const Text(
                                'Welcome to',
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              
                              const SizedBox(height: 8),
                              
                              const Text(
                                'Cal Dogs AI',
                                style: TextStyle(
                                  fontSize: 42,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1,
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              Text(
                                'Hi ${user?.displayName?.split(' ').first ?? 'there'}! 👋',
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: const Column(
                                  children: [
                                    Text(
                                      'AI-Powered Dog Nutrition',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Track meals, monitor health, and get personalized insights for your furry friend',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        height: 1.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Notification Permission Section (Mobile Only)
                if (!kIsWeb && _showNotificationStep)
                  AnimatedOpacity(
                    opacity: _showNotificationStep ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: _buildNotificationSection(),
                  ),
                
                // Continue Button
                AnimatedOpacity(
                  opacity: _canContinue() ? 1.0 : 0.3,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _canContinue() ? _continueToApp : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6366F1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isRequestingPermission
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                              ),
                            )
                          : const Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Skip option for notifications
                if (!kIsWeb && _showNotificationStep && !_permissionGranted)
                  TextButton(
                    onPressed: _continueToApp,
                    child: const Text(
                      'Skip for now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              _permissionGranted ? Icons.notifications_active : Icons.notifications,
              color: Colors.white,
              size: 30,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            _permissionGranted ? 'Notifications Enabled!' : 'Enable Meal Reminders',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            _permissionGranted 
                ? 'You\'ll get notified when it\'s time to feed your dog'
                : 'Never miss a meal! Get reminders for your dog\'s feeding schedule',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          
          if (!_permissionGranted) ...[
            const SizedBox(height: 20),
            
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              child: ElevatedButton.icon(
                onPressed: _isRequestingPermission ? null : _requestNotificationPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isRequestingPermission
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.notifications_active, size: 20),
                label: Text(
                  _isRequestingPermission ? 'Requesting...' : 'Enable Notifications',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _canContinue() {
    return kIsWeb || !_showNotificationStep || _permissionGranted || !_isRequestingPermission;
  }

  Future<void> _requestNotificationPermission() async {
    if (_isRequestingPermission) return;
    
    setState(() {
      _isRequestingPermission = true;
    });

    try {
      final granted = await _notificationService.requestPermissions();
      
      if (mounted) {
        setState(() {
          _permissionGranted = granted;
          _isRequestingPermission = false;
        });

        if (granted) {
          // Show success feedback
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Notifications enabled! You\'ll get meal reminders.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          // Show info about manual enabling
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can enable notifications later in Settings'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error requesting notification permission: $e');
      if (mounted) {
        setState(() {
          _isRequestingPermission = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _continueToApp() {
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      // Fallback navigation if no callback provided
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }
}
