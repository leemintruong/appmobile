import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';

import 'add_meal_screen.dart';
import 'report_screen.dart';
import 'profile_screen.dart';
import 'food_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _openAddMeal() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddMealScreen()),
    );

    if (mounted && result == true) {
      _loadHomeData();
    }
  }

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

  num _readNumber(List<String> keys, {num fallback = 0}) {
    for (final key in keys) {
      final v = _dailyReport[key];

      if (v is num) return v;

      if (v != null) {
        final parsed = num.tryParse(v.toString());
        if (parsed != null) return parsed;
      }
    }

    final nutrition = _dailyReport['nutrition'];
    if (nutrition is Map<String, dynamic>) {
      for (final key in keys) {
        final v = nutrition[key];

        if (v is num) return v;

        if (v != null) {
          final parsed = num.tryParse(v.toString());
          if (parsed != null) return parsed;
        }
      }
    }

    return fallback;
  }

  String _readProfile(List<String> keys, {String fallback = ''}) {
    for (final key in keys) {
      final v = _profile[key];

      if (v != null && v.toString().isNotEmpty) return v.toString();
    }

    return fallback;
  }

  List<dynamic> _mealList() {
    final meals = _meals['meals'];
    if (meals is List) return meals;
    return [];
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);

    if (index == 0 || index == 3) {
      _loadHomeData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _homePage(),
      const FoodListScreen(),
      const ReportScreen(),
      ProfileScreen(profile: _profile),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : pages[_currentIndex],
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _homePage() {
    final goal = _readNumber([
      'daily_calorie_goal',
      'calorie_goal',
    ], fallback: 2000);

    final used = _readNumber(['total_calories', 'calories'], fallback: 750);

    final remaining = goal - used;

    final protein = _readNumber(['total_protein', 'protein'], fallback: 60);

    final carbs = _readNumber(['total_carbs', 'carbs'], fallback: 250);

    final fat = _readNumber(['total_fat', 'fat'], fallback: 44);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadHomeData,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
          children: [
            _topHeader(),
            const SizedBox(height: 18),
            _calorieOverview(goal: goal, used: used, remaining: remaining),
            const SizedBox(height: 18),
            _macroCard(protein: protein, carbs: carbs, fat: fat),
            const SizedBox(height: 22),
            _mealJournal(),
            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _openAddMeal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  '+ Thêm bữa ăn',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.favorite, color: AppColors.primary, size: 18),
              SizedBox(width: 6),
              Text(
                'SứcKhỏe',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Thứ Sáu, 12 Tháng',
              style: TextStyle(color: AppColors.textGrey, fontSize: 14),
            ),
            Text(
              'Tổng quan hằng ngày',
              style: TextStyle(color: AppColors.textLight, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _calorieOverview({
    required num goal,
    required num used,
    required num remaining,
  }) {
    final progress = goal == 0 ? 0.0 : (used / goal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Calo còn lại',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '${remaining.toStringAsFixed(0)} kcal',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mục tiêu: ${goal.toStringAsFixed(0)} kcal · Đã dùng: ${used.toStringAsFixed(0)} kcal',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _calorieMini('Tiêu thụ', '${used.toStringAsFixed(0)} kcal'),
                    _calorieMini(
                      'Còn lại',
                      '${remaining.toStringAsFixed(0)} kcal',
                      green: true,
                    ),
                    _calorieMini('Mục tiêu', '${goal.toStringAsFixed(0)} kcal'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Center(
              child: Text('☘️', style: TextStyle(fontSize: 36)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _calorieMini(String title, String value, {bool green = false}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: green ? AppColors.primary : AppColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroCard({
    required num protein,
    required num carbs,
    required num fat,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Phân bổ macro',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Text('🚀', style: TextStyle(fontSize: 24)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Protein · Carbs · Fat',
            style: TextStyle(color: AppColors.textGrey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _macroLine(
            'Protein',
            '${protein.toStringAsFixed(0)}g',
            0.30,
            AppColors.primary,
          ),
          const SizedBox(height: 16),
          _macroLine(
            'Carbs',
            '${carbs.toStringAsFixed(0)}g',
            0.50,
            AppColors.protein,
          ),
          const SizedBox(height: 16),
          _macroLine(
            'Fat',
            '${fat.toStringAsFixed(0)}g',
            0.20,
            AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _macroLine(String label, String value, double percent, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(color: AppColors.textGrey)),
            const Spacer(),
            Text(
              '${(percent * 100).toStringAsFixed(0)}% · $value',
              style: const TextStyle(color: AppColors.textDark, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 9,
            color: color,
            backgroundColor: AppColors.border,
          ),
        ),
      ],
    );
  }

  Widget _mealJournal() {
    final meals = _mealList();

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
            child: Row(
              children: [
                const Text(
                  'Nhật ký bữa ăn hôm nay',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${meals.length} mục',
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (meals.isEmpty) ...[
            _mealRow('Sáng', '08:00 · 420 kcal', 'Đã ghi', true),
            _mealRow('Trưa', '12:30 · 640 kcal', 'Đã ghi', true),
            _mealRow('Tối', '19:00 · 520 kcal', 'Chưa', false),
            _mealRow('Snack', '15:30 · 150 kcal', 'Đã ghi', true),
          ] else
            ...meals.map((m) {
              final mealType = _mealLabel(m['meal_type']?.toString() ?? '');
              final kcal = m['total_calories'] ?? 0;
              return _mealRow(
                mealType,
                '${NumberFormatHelper.format(kcal)} kcal',
                'Đã ghi',
                true,
              );
            }),
        ],
      ),
    );
  }

  Widget _mealRow(String title, String subtitle, String status, bool done) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                const Text('🍲  🥘  +1 mục', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: done ? AppColors.primary : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                status,
                style: TextStyle(
                  color: done ? AppColors.primary : AppColors.warning,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.035),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  String _mealLabel(String type) {
    switch (type) {
      case 'breakfast':
        return 'Sáng';
      case 'lunch':
        return 'Trưa';
      case 'dinner':
        return 'Tối';
      case 'snack':
        return 'Snack';
      default:
        return type;
    }
  }

  Widget _bottomNav() {
    return Container(
      height: 66,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _navItem(0, Icons.home, 'Trang chủ'),
          _navItem(1, Icons.restaurant, 'Thực phẩm'),
          _navItem(2, Icons.show_chart, 'Báo cáo'),
          _navItem(3, Icons.person, 'Hồ sơ'),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final selected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onNavTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textGrey,
              size: 23,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textGrey,
                fontSize: 11,
              ),
            ),
          ],
        ),
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
