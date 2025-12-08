import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pupshape/config/theme.dart';
import 'package:pupshape/providers/auth_provider.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Fade Animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    
    // Scale Animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    // Slide Animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    
    // Start animations
    _fadeController.forward();
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _slideController.forward();
    });
    
    // Navigate after delay
    Timer(const Duration(seconds: 3), () {
      _navigateBasedOnAuthState();
    });
  }
  Future<void> _navigateBasedOnAuthState() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (!hasSeenOnboarding) {
      // First time user - show onboarding
      Navigator.of(context).pushReplacementNamed('/onboarding');
    } else if (authProvider.user != null) {
      // Returning user who is signed in - go to start screen (paywall check)
      Navigator.of(context).pushReplacementNamed('/start');
    } else {
      // Returning user who is not signed in - go to auth screen
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              // Animated Logo
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildLogo(),
                ),
              ),
              const SizedBox(height: 40),
              
              // Animated Text
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      const Text(
                        'PupShape',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'AI-Powered Weight Coach',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondaryColor,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Loading Indicator
              FadeTransition(
                opacity: _fadeAnimation,
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Dog silhouette transformation animation
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 2000),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return CustomPaint(
                  size: const Size(120, 120),
                  painter: DogTransformationPainter(progress: value),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for dog transformation animation (round to fit)
class DogTransformationPainter extends CustomPainter {
  final double progress;

  DogTransformationPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    
    // Interpolate from round (chubby) dog to fit dog
    final bodyWidth = 40 + (20 * (1 - progress)); // Gets narrower
    final bodyHeight = 50.0;
    
    // Draw body (rounded rectangle that gets narrower)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: bodyWidth,
        height: bodyHeight,
      ),
      Radius.circular(bodyWidth / 2),
    );
    canvas.drawRRect(bodyRect, paint);
    
    // Draw head
    canvas.drawCircle(
      Offset(center.dx, center.dy - 30),
      18,
      paint,
    );
    
    // Draw ears
    canvas.drawCircle(
      Offset(center.dx - 12, center.dy - 38),
      8,
      paint,
    );
    canvas.drawCircle(
      Offset(center.dx + 12, center.dy - 38),
      8,
      paint,
    );
    
    // Draw legs (get more visible as dog gets fit)
    final legPaint = Paint()
      ..color = AppTheme.primaryColor.withOpacity(0.7 + (0.3 * progress))
      ..style = PaintingStyle.fill;
    
    final legWidth = 8.0;
    final legHeight = 20.0;
    
    // Front legs
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(center.dx - 15, center.dy + 15, legWidth, legHeight),
        const Radius.circular(4),
      ),
      legPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(center.dx + 7, center.dy + 15, legWidth, legHeight),
        const Radius.circular(4),
      ),
      legPaint,
    );
    
    // Tail
    final tailPath = Path()
      ..moveTo(center.dx + bodyWidth / 2, center.dy)
      ..quadraticBezierTo(
        center.dx + bodyWidth / 2 + 15,
        center.dy - 10,
        center.dx + bodyWidth / 2 + 10,
        center.dy - 20,
      );
    canvas.drawPath(
      tailPath,
      Paint()
        ..color = AppTheme.primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(DogTransformationPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
