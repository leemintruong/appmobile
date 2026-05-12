import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';

import 'add_meal_screen.dart';
import 'report_screen.dart';
import 'weight_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  bool _isLoading = true;
  Map<String, dynamic> _profile = {};
  Map<String, dynamic> _dailyReport = {};
  Map<String, dynamic> _meals = {};

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Map<String, dynamic> _normalizeObject(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['data'] is Map<String, dynamic>) {
        return data['data'];
      }

      if (data['profile'] is Map<String, dynamic>) {
        return data['profile'];
      }

      if (data['user'] is Map<String, dynamic>) {
        return data['user'];
      }

      if (data['report'] is Map<String, dynamic>) {
        return data['report'];
      }

      return data;
    }

    return {};
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profileResult = await ApiService.getProfile();
      final reportResult = await ApiService.getDailyReport();
      final mealsResult = await ApiService.getMeals();

      setState(() {
        _profile = _normalizeObject(profileResult);
        _dailyReport = _normalizeObject(reportResult);
        _meals = _normalizeObject(mealsResult);
      });

      print('HOME PROFILE NORMALIZED: $_profile');
      print('HOME REPORT NORMALIZED: $_dailyReport');
      print('HOME MEALS NORMALIZED: $_meals');
    } catch (e) {
      print('LOAD HOME DATA ERROR: $e');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không tải được dữ liệu: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getProfileValue(List<String> keys, {String fallback = '--'}) {
    for (final key in keys) {
      final value = _profile[key];

      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }

  num _getReportNumber(List<String> keys, {num fallback = 0}) {
    for (final key in keys) {
      final value = _dailyReport[key];

      if (value is num) return value;

      if (value != null) {
        final parsed = num.tryParse(value.toString());
        if (parsed != null) return parsed;
      }
    }

    return fallback;
  }

  Future<void> _openAddMeal() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddMealScreen()),
    );

    if (mounted && result == true) {
      _loadHomeData();
    }
  }

  Future<void> _openReport() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReportScreen()),
    );

    if (mounted) {
      _loadHomeData();
    }
  }

  Future<void> _openWeight() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WeightScreen()),
    );

    if (mounted) {
      _loadHomeData();
    }
  }

  void _handleBottomTap(int index) {
    if (index == 1) {
      _openAddMeal();
      return;
    }

    if (index == 2) {
      _openReport();
      return;
    }

    if (index == 3) {
      _openWeight();
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    if (index == 0 || index == 4) {
      _loadHomeData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = _currentIndex == 4
        ? ProfileScreen(profile: _profile)
        : _buildDashboard();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : screen,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textGrey,
        type: BottomNavigationBarType.fixed,
        onTap: _handleBottomTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Thêm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Báo cáo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_weight_outlined),
            activeIcon: Icon(Icons.monitor_weight),
            label: 'Cân nặng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    final name = _getProfileValue(['name', 'full_name'], fallback: 'Bạn');
    final dailyGoal = _getProfileValue([
      'daily_calorie_goal',
      'calorie_goal',
    ], fallback: '0');

    final totalCalories = _getReportNumber([
      'total_calories',
      'calories',
      'calorie',
    ], fallback: 0);

    final totalProtein = _getReportNumber([
      'total_protein',
      'protein',
    ], fallback: 0);

    final totalCarbs = _getReportNumber(['total_carbs', 'carbs'], fallback: 0);

    final totalFat = _getReportNumber(['total_fat', 'fat'], fallback: 0);

    final goalNumber = num.tryParse(dailyGoal) ?? 0;
    final progress = goalNumber == 0 ? 0.0 : (totalCalories / goalNumber);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadHomeData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _headerCard(name),
            const SizedBox(height: 16),
            _calorieCard(
              totalCalories: totalCalories,
              dailyGoal: goalNumber,
              progress: progress.clamp(0.0, 1.0),
            ),
            const SizedBox(height: 16),
            _macroCards(
              protein: totalProtein,
              carbs: totalCarbs,
              fat: totalFat,
            ),
            const SizedBox(height: 16),
            _mealPreview(),
          ],
        ),
      ),
    );
  }

  Widget _headerCard(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Xin chào, $name!',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Hãy ghi lại bữa ăn để theo dõi dinh dưỡng hôm nay.',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _calorieCard({
    required num totalCalories,
    required num dailyGoal,
    required double progress,
  }) {
    final remaining = dailyGoal - totalCalories;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calo hôm nay',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _miniInfo(
                  'Đã nạp',
                  '${totalCalories.toStringAsFixed(0)} kcal',
                ),
              ),
              Expanded(
                child: _miniInfo(
                  'Mục tiêu',
                  '${dailyGoal.toStringAsFixed(0)} kcal',
                ),
              ),
              Expanded(
                child: _miniInfo(
                  remaining >= 0 ? 'Còn lại' : 'Vượt',
                  '${remaining.abs().toStringAsFixed(0)} kcal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(20),
            color: AppColors.primary,
            backgroundColor: AppColors.primary.withOpacity(0.15),
          ),
        ],
      ),
    );
  }

  Widget _miniInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _macroCards({
    required num protein,
    required num carbs,
    required num fat,
  }) {
    return Row(
      children: [
        Expanded(
          child: _macroCard(
            title: 'Protein',
            value: '${protein.toStringAsFixed(1)}g',
            icon: Icons.fitness_center,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _macroCard(
            title: 'Carb',
            value: '${carbs.toStringAsFixed(1)}g',
            icon: Icons.rice_bowl,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _macroCard(
            title: 'Fat',
            value: '${fat.toStringAsFixed(1)}g',
            icon: Icons.water_drop,
          ),
        ),
      ],
    );
  }

  Widget _macroCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mealPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nhật ký hôm nay',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _meals.isEmpty
                ? 'Chưa có dữ liệu bữa ăn hoặc API trả về rỗng.'
                : 'Đã tải dữ liệu bữa ăn từ backend.',
            style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
