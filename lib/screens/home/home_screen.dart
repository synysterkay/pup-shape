import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pupshape/providers/auth_provider.dart';
import 'package:pupshape/providers/dog_provider.dart';
import 'package:pupshape/providers/meal_provider.dart';
import 'package:pupshape/screens/dogs/dog_profile_screen.dart';
import 'package:pupshape/screens/meals/meal_logging_screen.dart';
import 'package:pupshape/screens/health/health_insights_screen.dart';
import 'package:pupshape/screens/profile/profile_screen.dart';
import 'package:pupshape/screens/settings/settings_screen.dart';
import 'package:pupshape/widgets/dog_selector.dart';
import 'package:pupshape/widgets/daily_summary_card.dart';
import 'package:pupshape/widgets/recent_meals_card.dart';
import 'package:pupshape/widgets/quick_actions_card.dart';
import 'package:pupshape/services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasNotificationPermission = false;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    print('🏠 HomeScreen initState called - ${widget.key}');
    
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeHomeScreen();
    });
  }

  @override
  void dispose() {
    print('🏠 HomeScreen dispose called - ${widget.key}');
    super.dispose();
  }

  Future<void> _initializeHomeScreen() async {
    if (!mounted) return;
    
    // Check notification permission status (only on mobile)
    if (!kIsWeb) {
      try {
        _hasNotificationPermission = await _notificationService.areNotificationsEnabled();
        print('📱 Notification permission: $_hasNotificationPermission');
        if (mounted) setState(() {});
      } catch (e) {
        print('⚠️ Error checking notification permission: $e');
      }
    }
    
    // Load data
    await _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    try {
      print('📊 Loading HomeScreen data...');
      
      final dogProvider = Provider.of<DogProvider>(context, listen: false);
      await dogProvider.fetchDogs();

      if (!mounted) return;
      print('🐕 Dogs loaded: ${dogProvider.dogs.length}');

      if (dogProvider.selectedDog != null) {
        final mealProvider = Provider.of<MealProvider>(context, listen: false);
        await mealProvider.fetchMealsForDog(dogProvider.selectedDog!.id);

        if (!mounted) return;
        print('🍽️ Meals loaded for: ${dogProvider.selectedDog!.name}');
      }

      print('✅ HomeScreen data loading completed');
    } catch (e) {
      print('❌ Error loading HomeScreen data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🏠 HomeScreen build called');
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Cal Dogs AI'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Notification icon with status indicator
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: _handleNotificationTap,
              ),
              if (!kIsWeb && !_hasNotificationPermission)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: Color(0xFF6366F1)),
                    SizedBox(width: 12),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, color: Color(0xFF6366F1)),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
              if (!kIsWeb) ...[
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'notifications',
                  child: Row(
                    children: [
                      Icon(
                        _hasNotificationPermission 
                            ? Icons.notifications 
                            : Icons.notifications_off,
                        color: _hasNotificationPermission 
                            ? Colors.green 
                            : Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      Text(_hasNotificationPermission 
                          ? 'Notifications On' 
                          : 'Enable Notifications'),
                    ],
                  ),
                ),
              ],
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Notification permission banner (only show on mobile if no permission)
            if (!kIsWeb && !_hasNotificationPermission)
              _buildNotificationBanner(),
            
            // Main content
            Expanded(
              child: Consumer<DogProvider>(
                builder: (context, dogProvider, child) {
                  print('🔄 Building content - dogs: ${dogProvider.dogs.length}, loading: ${dogProvider.isLoading}');

                  if (dogProvider.isLoading) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading your dogs...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (dogProvider.dogs.isEmpty) {
                    return _buildNoDogState();
                  }

                  return RefreshIndicator(
                    onRefresh: _loadData,
                    color: const Color(0xFF6366F1),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const DogSelector(),
                                  const SizedBox(height: 16),
                                  const QuickActionsCard(),
                                  const SizedBox(height: 16),
                                  const DailySummaryCard(),
                                  const SizedBox(height: 16),
                                  const RecentMealsCard(),
                                  const SizedBox(height: 16),
                                  _buildHealthInsightsPreview(),
                                  const SizedBox(height: 100), // Extra space for FAB
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const MealLoggingScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.restaurant, color: Colors.white),
      ),
    );
  }

  Widget _buildNotificationBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.withOpacity(0.1), Colors.red.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_off,
            color: Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable Meal Reminders',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Get notified when it\'s time to feed your dog',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _requestNotificationPermission,
            child: const Text(
              'Enable',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDogState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
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
            const Text(
              'No Dogs Added Yet',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add your first dog to start tracking their nutrition and health with AI-powered insights.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DogProfileScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Dog'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthInsightsPreview() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Colors.purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Health Insights',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const HealthInsightsScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<DogProvider>(
              builder: (context, dogProvider, child) {
                if (dogProvider.selectedDog == null) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey),
                        SizedBox(width: 12),
                        Text(
                          'No dog selected',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final dog = dogProvider.selectedDog!;
                return Column(
                  children: [
                    _buildInsightRow(
                      'Daily Calorie Target',
                      '${dog.dailyCaloricNeeds.toInt()} kcal',
                      Icons.local_fire_department,
                      Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _buildInsightRow(
                      'Current Weight',
                      '${dog.weight.toStringAsFixed(1)} kg',
                      Icons.monitor_weight,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildInsightRow(
                      'Activity Level',
                      dog.activityLevel.toUpperCase(),
                      Icons.directions_run,
                      Colors.green,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightRow(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap() {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifications are not available on web'),
        ),
      );
      return;
    }

    if (_hasNotificationPermission) {
      _showNotificationSettings();
    } else {
      _requestNotificationPermission();
    }
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.notifications, color: Color(0xFF6366F1)),
            SizedBox(width: 12),
            Text('Notification Settings'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.schedule, color: Colors.green),
              title: const Text('Meal Reminders'),
              subtitle: const Text('Get notified before meal times'),
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  // Handle toggle
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.analytics, color: Colors.blue),
              title: const Text('Daily Summary'),
              subtitle: const Text('Daily nutrition reports'),
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  // Handle toggle
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await _notificationService.showTestNotification();
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test notification sent!'),
                    ),
                  );
                }
              },
              child: const Text('Send Test Notification'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestNotificationPermission() async {
    if (kIsWeb) return;

    try {
      final granted = await _notificationService.requestPermissions();
      
      if (mounted) {
        setState(() {
          _hasNotificationPermission = granted;
        });

        if (granted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Notifications enabled! You\'ll get meal reminders.'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Schedule notifications for existing dogs
          final dogProvider = Provider.of<DogProvider>(context, listen: false);
          for (final dog in dogProvider.getDogsWithReminders()) {
            await _notificationService.scheduleMealReminders(dog);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Notification permission denied. You can enable it in settings.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error requesting notification permission: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleMenuSelection(String value) {
    if (!mounted) return;

    switch (value) {
      case 'profile':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ProfileScreen(),
          ),
        );
        break;
      case 'settings':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const SettingsScreen(),
          ),
        );
        break;
      case 'notifications':
        if (_hasNotificationPermission) {
          _showNotificationSettings();
        } else {
          _requestNotificationPermission();
        }
        break;
      case 'logout':
        _showLogoutDialog();
        break;
    }
  }

  void _showLogoutDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 12),
            Text('Sign Out'),
          ],
        ),
        content: const Text('Are you sure you want to sign out of Cal Dogs AI?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error signing out: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
