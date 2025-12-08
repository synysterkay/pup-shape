import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pupshape/config/theme.dart';
import 'package:pupshape/providers/dog_provider.dart';
import 'package:pupshape/providers/plan_provider.dart';
import 'package:pupshape/models/weight_log.dart';
import 'package:pupshape/models/milestone.dart';
import 'package:pupshape/models/progress_photo.dart';
import 'package:pupshape/services/progress_service.dart';
import 'package:pupshape/services/progress_photo_service.dart';
import 'package:pupshape/screens/progress/weight_logging_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final ProgressService _progressService = ProgressService();
  final ProgressPhotoService _photoService = ProgressPhotoService();
  
  List<WeightLog> _weightLogs = [];
  List<Milestone> _milestones = [];
  List<ProgressPhoto> _progressPhotos = [];
  int _currentStreak = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final dogProvider = Provider.of<DogProvider>(context, listen: false);
    final dog = dogProvider.selectedDog;

    if (dog == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final logs = await _progressService.getWeightLogs(dog.id);
      final milestones = await _progressService.getMilestones(dog.id);
      final streak = await _progressService.calculateStreak(dog.id);
      final photos = await _photoService.getProgressPhotos(dog.id);

      if (mounted) {
        setState(() {
          _weightLogs = logs;
          _milestones = milestones;
          _currentStreak = streak;
          _progressPhotos = photos;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading progress data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Progress',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppTheme.primaryColor),
            onPressed: _exportReport,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsOverview(),
            const SizedBox(height: 24),
            _buildWeightChart(),
            const SizedBox(height: 24),
            _buildMilestones(),
            const SizedBox(height: 24),
            _buildProgressPhotos(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const WeightLoggingScreen(),
            ),
          ).then((_) => _loadData()); // Refresh data after logging weight
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.scale, color: Colors.white),
        label: const Text(
          'Log Weight',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    final dogProvider = Provider.of<DogProvider>(context);
    final planProvider = Provider.of<PlanProvider>(context);
    
    final dog = dogProvider.selectedDog;
    final plan = planProvider.currentPlan;
    
    if (dog == null || plan == null) {
      return const SizedBox.shrink();
    }

    final startWeight = plan.startWeight;
    final currentWeight = _weightLogs.isNotEmpty ? _weightLogs.last.weight : dog.weight;
    final targetWeight = plan.targetWeight;
    final weightLost = startWeight - currentWeight;
    final progressPercent = ((weightLost / (startWeight - targetWeight)) * 100).clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Start', '${startWeight.toStringAsFixed(1)}kg'),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
              _buildStatItem('Current', '${currentWeight.toStringAsFixed(1)}kg'),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
              _buildStatItem('Target', '${targetWeight.toStringAsFixed(1)}kg'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weight Lost',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${weightLost.toStringAsFixed(1)}kg',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${progressPercent.toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressPercent / 100,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildWeightChart() {
    if (_weightLogs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.show_chart, size: 48, color: AppTheme.textSecondaryColor),
              SizedBox(height: 12),
              Text(
                'No weight data yet',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final weights = _weightLogs.map((log) => log.weight).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final weightRange = maxWeight - minWeight;
    final chartMinY = (minWeight - weightRange * 0.1).floorToDouble();
    final chartMaxY = (maxWeight + weightRange * 0.1).ceilToDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weight Trend',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}kg',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _weightLogs.length && index % 2 == 0) {
                          final date = _weightLogs[index].date;
                          return Text(
                            DateFormat('MMM d').format(date),
                            style: const TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 10,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (_weightLogs.length - 1).toDouble(),
                minY: chartMinY,
                maxY: chartMaxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: _weightLogs.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value.weight,
                      );
                    }).toList(),
                    isCurved: true,
                    gradient: AppTheme.primaryGradient,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: AppTheme.primaryColor,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.3),
                          AppTheme.primaryColor.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestones() {
    if (_milestones.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Milestones',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        ..._milestones.map((milestone) => _buildMilestoneCard(milestone)),
      ],
    );
  }

  Widget _buildMilestoneCard(Milestone milestone) {
    // All milestones in the list are already achieved
    final isCompleted = true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isCompleted 
            ? Border.all(color: AppTheme.primaryColor, width: 2)
            : Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCompleted 
                  ? AppTheme.primaryColor 
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.flag_outlined,
              color: isCompleted ? Colors.white : Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCompleted 
                        ? AppTheme.textPrimaryColor 
                        : AppTheme.textSecondaryColor,
                  ),
                ),
                Text(
                  milestone.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          if (isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '✨ Done',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressPhotos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progress Photos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            TextButton.icon(
              onPressed: _showAddPhotoOptions,
              icon: const Icon(Icons.add_a_photo, size: 18),
              label: const Text('Add Photo'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _progressPhotos.isEmpty
            ? _buildEmptyPhotosState()
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _progressPhotos.length,
                itemBuilder: (context, index) {
                  final photo = _progressPhotos[index];
                  return _buildPhotoCard(photo);
                },
              ),
      ],
    );
  }

  Widget _buildEmptyPhotosState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.photo_camera, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No progress photos yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Capture your dog\'s transformation journey!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(ProgressPhoto photo) {
    return GestureDetector(
      onTap: () => _viewPhotoDetails(photo),
      onLongPress: () => _showPhotoOptions(photo),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                photo.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 40, color: Colors.white),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: 4,
              left: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  DateFormat('MMM d').format(photo.date),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            if (photo.weight != null)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${photo.weight!.toStringAsFixed(1)}kg',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _addProgressPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryColor),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _addProgressPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addProgressPhoto(ImageSource source) async {
    final dogProvider = Provider.of<DogProvider>(context, listen: false);
    final dog = dogProvider.selectedDog;
    
    if (dog == null) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image == null) return;

      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Uploading photo...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Upload photo
      final photo = await _photoService.uploadProgressPhoto(
        dogId: dog.id,
        imageFile: image,
        weight: dog.weight,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        setState(() {
          _progressPhotos.insert(0, photo);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 Progress photo added successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading photo: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _viewPhotoDetails(ProgressPhoto photo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Image.network(photo.imageUrl),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMMM d, yyyy').format(photo.date),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  if (photo.weight != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.fitness_center, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          '${photo.weight!.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (photo.notes != null && photo.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      photo.notes!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoOptions(ProgressPhoto photo) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Photo'),
              onTap: () {
                Navigator.pop(context);
                _deletePhoto(photo);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePhoto(ProgressPhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _photoService.deleteProgressPhoto(photo.id, photo.imageUrl);
      
      if (mounted) {
        setState(() {
          _progressPhotos.removeWhere((p) => p.id == photo.id);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo deleted'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting photo: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _exportReport() {
    // TODO: Generate PDF report with weight history, photos, and meal logs
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📄 Generating vet report...'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}
