import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pupshape/providers/auth_provider.dart';
import 'package:pupshape/providers/dog_provider.dart';
import 'package:pupshape/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  
  // Notification settings
  bool _notificationsEnabled = true;
  bool _mealReminders = true;
  bool _healthAlerts = true;
  bool _weeklyReports = false;
  bool _missedMealAlerts = true;
  
  // Notification timing
  int _reminderMinutesBefore = 30;
  TimeOfDay _dailySummaryTime = const TimeOfDay(hour: 20, minute: 0);
  
  // Other settings
  String _selectedTheme = 'System';
  String _selectedLanguage = 'English';
  
  bool _isLoading = false;
  bool _hasNotificationPermission = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkNotificationPermission();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _mealReminders = prefs.getBool('meal_reminders') ?? true;
        _healthAlerts = prefs.getBool('health_alerts') ?? true;
        _weeklyReports = prefs.getBool('weekly_reports') ?? false;
        _missedMealAlerts = prefs.getBool('missed_meal_alerts') ?? true;
        _reminderMinutesBefore = prefs.getInt('reminder_minutes_before') ?? 30;
        _selectedTheme = prefs.getString('selected_theme') ?? 'System';
        _selectedLanguage = prefs.getString('selected_language') ?? 'English';
        
        // Load daily summary time
        final summaryHour = prefs.getInt('daily_summary_hour') ?? 20;
        final summaryMinute = prefs.getInt('daily_summary_minute') ?? 0;
        _dailySummaryTime = TimeOfDay(hour: summaryHour, minute: summaryMinute);
      });
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await prefs.setBool('meal_reminders', _mealReminders);
      await prefs.setBool('health_alerts', _healthAlerts);
      await prefs.setBool('weekly_reports', _weeklyReports);
      await prefs.setBool('missed_meal_alerts', _missedMealAlerts);
      await prefs.setInt('reminder_minutes_before', _reminderMinutesBefore);
      await prefs.setString('selected_theme', _selectedTheme);
      await prefs.setString('selected_language', _selectedLanguage);
      await prefs.setInt('daily_summary_hour', _dailySummaryTime.hour);
      await prefs.setInt('daily_summary_minute', _dailySummaryTime.minute);
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  Future<void> _checkNotificationPermission() async {
    final hasPermission = await _notificationService.areNotificationsEnabled();
    setState(() {
      _hasNotificationPermission = hasPermission;
    });
  }

  Future<void> _requestNotificationPermission() async {
    setState(() {
      _isLoading = true;
    });

    final granted = await _notificationService.requestPermissions();
    
    setState(() {
      _hasNotificationPermission = granted;
      _isLoading = false;
    });

    if (granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification permissions granted!'),
          backgroundColor: Colors.green,
        ),
      );
      await _updateNotificationSchedules();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification permissions are required for meal reminders'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _updateNotificationSchedules() async {
    if (!_notificationsEnabled || !_hasNotificationPermission) {
      await _notificationService.cancelAllNotifications();
      return;
    }

    final dogProvider = Provider.of<DogProvider>(context, listen: false);
    
    for (final dog in dogProvider.dogs) {
      if (_mealReminders) {
        // Update dog's reminder settings and reschedule
        final updatedDog = dog.copyWith(
          enableMealReminders: _mealReminders,
          reminderMinutesBefore: _reminderMinutesBefore,
        );
        await _notificationService.scheduleMealReminders(updatedDog);
      } else {
        await _notificationService.cancelMealReminders(dog.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Notifications Section
            _buildNotificationsSection(),
            const SizedBox(height: 24),
            
            // Appearance Section
            _buildAppearanceSection(),
            const SizedBox(height: 24),
            
            // Data & Privacy Section
            _buildDataPrivacySection(),
            const SizedBox(height: 24),
            
            // Support Section
            _buildSupportSection(),
            const SizedBox(height: 24),
            
            // About Section
            _buildAboutSection(),
            const SizedBox(height: 32),
            
            // Sign Out Button
            _buildSignOutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return _buildSettingsSection(
      'Notifications',
      Icons.notifications_outlined,
      Colors.blue,
      [
        // Permission status
        if (!_hasNotificationPermission)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Notification permissions required',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _requestNotificationPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Grant Permission'),
                  ),
                ),
              ],
            ),
          ),
        
        _buildSwitchTile(
          'Push Notifications',
          'Receive notifications on your device',
          _notificationsEnabled,
          (value) async {
            setState(() {
              _notificationsEnabled = value;
            });
            await _saveSettings();
            await _updateNotificationSchedules();
          },
        ),
        
        if (_notificationsEnabled && _hasNotificationPermission) ...[
          _buildSwitchTile(
            'Meal Reminders',
            'Get reminded when it\'s time to feed your dog',
            _mealReminders,
            (value) async {
              setState(() {
                _mealReminders = value;
              });
              await _saveSettings();
              await _updateNotificationSchedules();
            },
          ),
          
          if (_mealReminders)
            _buildReminderTimingTile(),
          
          _buildSwitchTile(
            'Missed Meal Alerts',
            'Get alerted if you haven\'t logged a meal',
            _missedMealAlerts,
            (value) async {
              setState(() {
                _missedMealAlerts = value;
              });
              await _saveSettings();
            },
          ),
          
          _buildSwitchTile(
            'Health Alerts',
            'Receive alerts about your dog\'s health',
            _healthAlerts,
            (value) async {
              setState(() {
                _healthAlerts = value;
              });
              await _saveSettings();
            },
          ),
          
          _buildSwitchTile(
            'Weekly Reports',
            'Get weekly nutrition summary reports',
            _weeklyReports,
            (value) async {
              setState(() {
                _weeklyReports = value;
              });
              await _saveSettings();
            },
          ),
          
          _buildDailySummaryTimeTile(),
        ],
        
        // Test notification button
        if (_notificationsEnabled && _hasNotificationPermission)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await _notificationService.showTestNotification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test notification sent!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.send),
                label: const Text('Send Test Notification'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                  side: const BorderSide(color: Color(0xFF6366F1)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReminderTimingTile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reminder timing',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'How early to remind you before meal time',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<int>(
            value: _reminderMinutesBefore,
            onChanged: (value) async {
              if (value != null) {
                setState(() {
                  _reminderMinutesBefore = value;
                });
                await _saveSettings();
                await _updateNotificationSchedules();
              }
            },
            items: [15, 30, 60, 120].map((minutes) {
              return DropdownMenuItem<int>(
                value: minutes,
                child: Text('${minutes}min'),
              );
            }).toList(),
            underline: const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySummaryTimeTile() {
    return InkWell(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: _dailySummaryTime,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF6366F1),
                ),
              ),
              child: child!,
            );
          },
        );
        
        if (picked != null && picked != _dailySummaryTime) {
          setState(() {
            _dailySummaryTime = picked;
          });
          await _saveSettings();
          
          // Reschedule daily summaries for all dogs
          final dogProvider = Provider.of<DogProvider>(context, listen: false);
          for (final dog in dogProvider.dogs) {
            await _notificationService.scheduleDailySummary(
              dog.id,
              dog.name,
              _dailySummaryTime,
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Summary Time',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'When to receive daily nutrition summaries',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  _dailySummaryTime.format(context),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6366F1),
                  ),
                ),
                               const SizedBox(width: 8),
                const Icon(
                  Icons.access_time,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return _buildSettingsSection(
      'Appearance',
      Icons.palette_outlined,
      Colors.purple,
      [
        _buildDropdownTile(
          'Theme',
          'Choose your preferred theme',
          _selectedTheme,
          ['Light', 'Dark', 'System'],
          (value) async {
            setState(() {
              _selectedTheme = value!;
            });
            await _saveSettings();
          },
        ),
        _buildDropdownTile(
          'Language',
          'Select your preferred language',
          _selectedLanguage,
          ['English', 'Spanish', 'French', 'German'],
          (value) async {
            setState(() {
              _selectedLanguage = value!;
            });
            await _saveSettings();
          },
        ),
      ],
    );
  }

  Widget _buildDataPrivacySection() {
    return _buildSettingsSection(
      'Data & Privacy',
      Icons.security_outlined,
      Colors.green,
      [
        _buildActionTile(
          'Export Data',
          'Download your data as a backup',
          Icons.download_outlined,
          () => _showExportDialog(),
        ),
        _buildActionTile(
          'Notification History',
          'View your notification settings and history',
          Icons.history,
          () => _showNotificationHistory(),
        ),
        _buildActionTile(
          'Delete Account',
          'Permanently delete your account and data',
          Icons.delete_outline,
          () => _showDeleteAccountDialog(),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return _buildSettingsSection(
      'Support',
      Icons.help_outline,
      Colors.orange,
      [
        _buildActionTile(
          'Help Center',
          'Get help and find answers to common questions',
          Icons.help_center_outlined,
          () => _showComingSoon('Help Center'),
        ),
        _buildActionTile(
          'Contact Support',
          'Get in touch with our support team',
          Icons.support_agent_outlined,
          () => _showComingSoon('Contact Support'),
        ),
        _buildActionTile(
          'Rate App',
          'Rate Cal Dogs AI on the app store',
          Icons.star_outline,
          () => _showComingSoon('Rate App'),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSettingsSection(
      'About',
      Icons.info_outline,
      Colors.grey,
      [
        _buildInfoTile('Version', '1.0.0'),
        _buildActionTile(
          'Privacy Policy',
          'Read our privacy policy',
          Icons.privacy_tip_outlined,
          () => _showComingSoon('Privacy Policy'),
        ),
        _buildActionTile(
          'Terms of Service',
          'Read our terms of service',
          Icons.description_outlined,
          () => _showComingSoon('Terms of Service'),
        ),
      ],
    );
  }

  Widget _buildSignOutSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.logout, color: Colors.red, size: 32),
          const SizedBox(height: 12),
          const Text(
            'Sign Out',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You can always sign back in later',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showSignOutDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(String title, String subtitle, String value, List<String> options, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: value,
            onChanged: onChanged,
            items: options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
            underline: const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? Colors.red : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationHistory() async {
    final pendingNotifications = await _notificationService.getPendingNotifications();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Notification History'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pending notifications: ${pendingNotifications.length}'),
              const SizedBox(height: 16),
              if (pendingNotifications.isNotEmpty) ...[
                const Text('Scheduled notifications:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...pendingNotifications.take(5).map((notification) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${notification.title}',
                    style: const TextStyle(fontSize: 14),
                  ),
                )),
                if (pendingNotifications.length > 5)
                  Text('... and ${pendingNotifications.length - 5} more'),
              ] else
                const Text('No pending notifications'),
            ],
          ),
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

  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Coming Soon'),
        content: Text('$feature will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              // Cancel all notifications before signing out
              await _notificationService.cancelAllNotifications();
              
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/auth');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Export Data'),
        content: const Text('Your data will be exported as a JSON file. This may take a few moments.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement data export
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data export started...')),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone. All your data including dog profiles, meal logs, and health insights will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement account deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion is not implemented yet'),
                  backgroundColor: Colors.red,
                ),
              );
            },
                       style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
