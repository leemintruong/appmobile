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
      if (data['data'] is Map<String, dynamic>) return data['data'];
      if (data['profile'] is Map<String, dynamic>) return data['profile'];
      if (data['user'] is Map<String, dynamic>) return data['user'];
      if (data['report'] is Map<String, dynamic>) return data['report'];
      return data;
    }
    return {};
  }

  Future<void> _loadHomeData() async {
    setState(() => _isLoading = true);

    try {
      final profileResult = await ApiService.getProfile();
      final reportResult = await ApiService.getDailyReport();
      final mealsResult = await ApiService.getMeals();

      if (!mounted) return;

      setState(() {
        _profile = _normalizeObject(profileResult);
        _dailyReport = _normalizeObject(reportResult);
        _meals = _normalizeObject(mealsResult);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không tải được dữ liệu: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getProfileValue(List<String> keys, {String fallback = '--'}) {
    for (final key in keys) {
      final value = _profile[key];
      if (value != null && value.toString().isNotEmpty) return value.toString();
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

    final nutrition = _dailyReport['nutrition'];
    if (nutrition is Map<String, dynamic>) {
      for (final key in keys) {
        final value = nutrition[key];

        if (value is num) return value;

        if (value != null) {
          final parsed = num.tryParse(value.toString());
          if (parsed != null) return parsed;
        }
      }
    }

    return fallback;
  }

  List<dynamic> _mealList() {
    final meals = _meals['meals'];
    if (meals is List) return meals;
    return [];
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

  void _handleBottomTap(int index) {
    setState(() => _currentIndex = index);

    if (index == 0 || index == 3) {
      _loadHomeData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildDashboard(),
      const AddMealScreen(),
      const ReportScreen(),
      ProfileScreen(profile: _profile),
    ];

    return Scaffold(
      backgroundColor: AppColors.pageGrey,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : pages[_currentIndex],
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _bottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _navItem(0, '🏠', 'Home'),
          _navItem(1, '🍽️', 'Meals'),
          _navItem(2, '📊', 'Report'),
          _navItem(3, '👤', 'Profile'),
        ],
      ),
    );
  }

  Widget _navItem(int index, String icon, String label) {
    final selected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _handleBottomTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textGrey,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final dailyGoalText = _getProfileValue([
      'daily_calorie_goal',
      'calorie_goal',
    ], fallback: '2000');

    final dailyGoal = num.tryParse(dailyGoalText) ?? 2000;

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

    final remaining = dailyGoal - totalCalories;
    final progress = dailyGoal == 0 ? 0.0 : (totalCalories / dailyGoal);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadHomeData,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
          children: [
            const Text(
              'Trang chủ',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Hôm nay',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            _calorieCard(
              totalCalories: totalCalories,
              dailyGoal: dailyGoal,
              remaining: remaining,
              progress: progress.clamp(0.0, 1.0),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _macroCard(
                    title: 'Protein',
                    value: '${totalProtein.toStringAsFixed(0)}g',
                    progress: 0.7,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _macroCard(
                    title: 'Carb',
                    value: '${totalCarbs.toStringAsFixed(0)}g',
                    progress: 0.58,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _macroCard(
                    title: 'Fat',
                    value: '${totalFat.toStringAsFixed(0)}g',
                    progress: 0.46,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Text(
              'Bữa ăn',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            _mealSection(),
            const SizedBox(height: 18),
            SizedBox(
              height: 58,
              child: ElevatedButton(
                onPressed: _openAddMeal,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  '+ Thêm bữa ăn',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _calorieCard({
    required num totalCalories,
    required num dailyGoal,
    required num remaining,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calo đã nạp',
            style: TextStyle(
              color: AppColors.textGrey,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                totalCalories.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 50,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Text(
                  '/ ${dailyGoal.toStringAsFixed(0)} kcal',
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 13,
              color: AppColors.primary,
              backgroundColor: AppColors.border,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            remaining >= 0
                ? 'Còn lại: ${remaining.toStringAsFixed(0)} kcal'
                : 'Vượt: ${remaining.abs().toStringAsFixed(0)} kcal',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroCard({
    required String title,
    required String value,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 116,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textGrey,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: AppColors.primary,
              backgroundColor: AppColors.border,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mealSection() {
    final meals = _mealList();

    if (meals.isEmpty) {
      return Column(
        children: [
          _mealCard('Sáng', 'Chưa ghi', '0 kcal'),
          const SizedBox(height: 12),
          _mealCard('Trưa', 'Chưa ghi', '0 kcal'),
          const SizedBox(height: 12),
          _mealCard('Tối', 'Chưa ghi', '0 kcal'),
        ],
      );
    }

    return Column(
      children: meals.map((meal) {
        final mealType = meal['meal_type']?.toString() ?? '';
        final title = _mealTypeLabel(mealType);
        final total = meal['total_calories'] ?? 0;
        final items = meal['items'];

        String subtitle = 'Đã ghi';
        if (items is List && items.isNotEmpty) {
          subtitle = items
              .take(2)
              .map((e) => e['food_name']?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .join(', ');
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _mealCard(
            title,
            subtitle,
            '${NumberFormatHelper.format(total)} kcal',
          ),
        );
      }).toList(),
    );
  }

  String _mealTypeLabel(String type) {
    switch (type) {
      case 'breakfast':
        return 'Sáng';
      case 'lunch':
        return 'Trưa';
      case 'dinner':
        return 'Tối';
      case 'snack':
        return 'Phụ';
      default:
        return type;
    }
  }

  Widget _mealCard(String title, String subtitle, String kcal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            kcal,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class NumberFormatHelper {
  static String format(dynamic value) {
    final n = num.tryParse(value.toString()) ?? 0;
    return n.toStringAsFixed(0);
  }
}
