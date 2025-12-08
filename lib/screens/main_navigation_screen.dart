import 'package:flutter/material.dart';
import 'package:pupshape/config/theme.dart';
import 'package:pupshape/screens/home/new_home_screen.dart';
import 'package:pupshape/screens/calendar/calendar_screen.dart';
import 'package:pupshape/screens/meals/meal_suggestions_screen.dart';
import 'package:pupshape/screens/progress/progress_screen.dart';
import 'package:pupshape/screens/profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  
  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<Widget> _screens = [
    const NewHomeScreen(),
    const CalendarScreen(),
    const MealSuggestionsScreen(),
    const ProgressScreen(),
    const ProfileScreen(),
  ];

  final List<NavigationItem> _navItems = [
    NavigationItem(
      icon: Icons.home_rounded,
      label: 'Home',
      activeColor: AppTheme.primaryColor,
    ),
    NavigationItem(
      icon: Icons.calendar_today_rounded,
      label: 'Plan',
      activeColor: const Color(0xFF10B981),
    ),
    NavigationItem(
      icon: Icons.restaurant_menu_rounded,
      label: 'Meals',
      activeColor: const Color(0xFFF59E0B),
    ),
    NavigationItem(
      icon: Icons.trending_up_rounded,
      label: 'Progress',
      activeColor: const Color(0xFF8B5CF6),
    ),
    NavigationItem(
      icon: Icons.person_rounded,
      label: 'Profile',
      activeColor: const Color(0xFFEC4899),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      _animationController.reset();
      _animationController.forward();
      
      // Haptic feedback
      // HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                _navItems.length,
                (index) => _buildNavItem(index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _navItems[index];
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? item.activeColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: Icon(
                item.icon,
                color: isSelected ? item.activeColor : AppTheme.textSecondaryColor,
                size: 24,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: SizedBox(
                width: isSelected ? 8 : 0,
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: isSelected ? null : 0,
              child: isSelected
                  ? Text(
                      item.label,
                      style: TextStyle(
                        color: item.activeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final Color activeColor;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.activeColor,
  });
}
