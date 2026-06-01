import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/app_events.dart';

import 'add_meal_screen.dart';
import 'report_screen.dart';
import 'profile_screen.dart';
import 'food_list_screen.dart';
import 'ai_scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isLoading = true;
  int _lastEventVersion = 0;
  Timer? _pollingTimer;

  Map<String, dynamic> _profile = {};
  Map<String, dynamic> _dailyReport = {};
  Map<String, dynamic> _meals = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastEventVersion = AppEvents.dataVersion.value;
    AppEvents.dataVersion.addListener(_handleDataEvent);
    _loadHomeData();

    // Refresh nhẹ để demo có cảm giác realtime hơn, không cần WebSocket.
    _pollingTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (mounted && _currentIndex == 0) _loadHomeData(silent: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppEvents.dataVersion.removeListener(_handleDataEvent);
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadHomeData(silent: true);
    }
  }

  void _handleDataEvent() {
    if (!mounted) return;
    if (_lastEventVersion != AppEvents.dataVersion.value) {
      _lastEventVersion = AppEvents.dataVersion.value;
      _loadHomeData(silent: true);
    }
  }

  Future<void> _openAddMeal() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddMealScreen()),
    );

    if (mounted && result == true) {
      AppEvents.notifyDataChanged();
      await _loadHomeData();
    }
  }

  Map<String, dynamic> _normalizeObject(dynamic data) =>
      ApiService.normalizeObject(data);

  Future<void> _loadHomeData({bool silent = false}) async {
    if (!silent && mounted) setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        ApiService.getProfile(),
        ApiService.getDailyReport(),
        ApiService.getMeals(),
      ]);

      if (!mounted) return;

      setState(() {
        _profile = _normalizeObject(results[0]);
        _dailyReport = _normalizeObject(results[1]);
        _meals = _normalizeObject(results[2]);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không tải được dữ liệu: $e')));
    } finally {
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  num _parseNumber(dynamic value, {num fallback = 0}) {
    if (value is num) return value;
    if (value != null) {
      final parsed = num.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  num _readNumber(List<String> keys, {num fallback = 0}) {
    final sources = <dynamic>[
      _dailyReport,
      _dailyReport['nutrition'],
      _dailyReport['goal'],
      _dailyReport['data'],
      _dailyReport['report'],
      _profile,
      _profile['profile'],
      _profile['goal'],
      _profile['data'],
      _meals,
    ];

    for (final source in sources) {
      if (source is Map) {
        for (final key in keys) {
          if (source.containsKey(key)) {
            return _parseNumber(source[key], fallback: fallback);
          }
        }
      }
    }

    return fallback;
  }

  num _readPositiveNumber(List<String> keys, {required num fallback}) {
    final value = _readNumber(keys, fallback: fallback);
    if (value <= 0) return fallback;
    return value;
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
    if (index == 0 || index == 3 || index == 4) {
      _loadHomeData(silent: true);
      AppEvents.notifyDataChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _homePage(),
      const FoodListScreen(),
      const AiScanScreen(showBackButton: false),
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
    final used = _readNumber(['total_calories', 'calories'], fallback: 0);
    final remaining = goal - used;

    final protein = _readNumber([
      'total_protein',
      'protein',
      'protein_total',
      'totalProtein',
    ], fallback: 0);
    final carbs = _readNumber([
      'total_carbs',
      'carbs',
      'carb',
      'totalCarbs',
    ], fallback: 0);
    final fat = _readNumber(['total_fat', 'fat', 'totalFat'], fallback: 0);

    final proteinGoal = _readPositiveNumber([
      'daily_protein_goal',
      'protein_goal',
      'target_protein',
      'proteinGoal',
    ], fallback: 100);
    final carbsGoal = _readPositiveNumber([
      'daily_carbs_goal',
      'carbs_goal',
      'target_carbs',
      'carbsGoal',
    ], fallback: 250);
    final fatGoal = _readPositiveNumber([
      'daily_fat_goal',
      'fat_goal',
      'target_fat',
      'fatGoal',
    ], fallback: 60);
    final water = _readNumber(['total_water_ml'], fallback: 0);
    final waterGoal = _readNumber(['daily_water_goal_ml'], fallback: 2000);

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
            _macroCard(
              protein: protein,
              carbs: carbs,
              fat: fat,
              proteinGoal: proteinGoal,
              carbsGoal: carbsGoal,
              fatGoal: fatGoal,
            ),
            const SizedBox(height: 18),
            _waterActivityCard(water: water, waterGoal: waterGoal),
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
    final name = _readProfile(['name'], fallback: 'Bạn');
    final today = DateTime.now();
    final dateText = '${today.day}/${today.month}/${today.year}';

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
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Chào, $name',
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              dateText,
              style: const TextStyle(color: AppColors.textLight, fontSize: 13),
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
    final progress = goal == 0 ? 0.0 : (used / goal).clamp(0.0, 1.0).toDouble();

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
                    fontWeight: FontWeight.w700,
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
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    color: AppColors.primary,
                    backgroundColor: AppColors.border,
                  ),
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
              child: Icon(Icons.eco, color: AppColors.primary, size: 38),
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
    required num proteinGoal,
    required num carbsGoal,
    required num fatGoal,
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
                  child: Icon(Icons.show_chart, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Đã nạp: ${protein.toStringAsFixed(0)}g protein · ${carbs.toStringAsFixed(0)}g carb · ${fat.toStringAsFixed(0)}g fat',
            style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _macroLine('Protein', protein, proteinGoal, AppColors.primary),
          const SizedBox(height: 16),
          _macroLine('Carbs', carbs, carbsGoal, AppColors.protein),
          const SizedBox(height: 16),
          _macroLine('Fat', fat, fatGoal, AppColors.warning),
        ],
      ),
    );
  }

  Widget _macroLine(String label, num value, num goal, Color color) {
    final percent = goal == 0 ? 0.0 : (value / goal).clamp(0.0, 1.0).toDouble();
    return Column(
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(color: AppColors.textGrey)),
            const Spacer(),
            Text(
              '${(percent * 100).toStringAsFixed(0)}% · ${value.toStringAsFixed(0)}g/${goal.toStringAsFixed(0)}g',
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

  Widget _waterActivityCard({required num water, required num waterGoal}) {
    final progress = waterGoal == 0
        ? 0.0
        : (water / waterGoal).clamp(0.0, 1.0).toDouble();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const Icon(Icons.water_drop, color: AppColors.protein, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nước uống hôm nay',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${water.toStringAsFixed(0)} / ${waterGoal.toStringAsFixed(0)} ml',
                  style: const TextStyle(color: AppColors.textGrey),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    color: AppColors.protein,
                    backgroundColor: AppColors.border,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
                  '${meals.length} bữa',
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (meals.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              child: Column(
                children: [
                  const Icon(
                    Icons.no_food,
                    color: AppColors.textLight,
                    size: 34,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Chưa có bữa ăn nào hôm nay',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Bấm “Thêm bữa ăn” để dữ liệu cập nhật ngay trên Home.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            ...meals.map((m) => _mealDetailCard(Map<String, dynamic>.from(m as Map))),
        ],
      ),
    );
  }

  Widget _mealDetailCard(Map<String, dynamic> map) {
    final mealType = _mealLabel(map['meal_type']?.toString() ?? '');
    final kcal = map['total_calories'] ?? 0;
    final protein = map['total_protein'] ?? 0;
    final carbs = map['total_carbs'] ?? 0;
    final fat = map['total_fat'] ?? 0;
    final items = map['items'] is List ? map['items'] as List : <dynamic>[];

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 10),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mealType,
                  style: const TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${NumberFormatHelper.format(kcal)} kcal',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'P ${NumberFormatHelper.format(protein)}g · C ${NumberFormatHelper.format(carbs)}g · F ${NumberFormatHelper.format(fat)}g',
            style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...items.map((item) {
              final it = Map<String, dynamic>.from(item as Map);
              final name = it['food_name'] ?? it['custom_food_name'] ?? 'Món ăn';
              final amount = NumberFormatHelper.format(it['amount']);
              final unit = it['amount_unit'] ?? '';
              final itemKcal = NumberFormatHelper.format(it['total_calories'] ?? it['calories']);
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const Icon(Icons.restaurant_menu, size: 14, color: AppColors.textLight),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$name · $amount$unit',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                      ),
                    ),
                    Text(
                      '$itemKcal kcal',
                      style: const TextStyle(color: AppColors.textDark, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              );
            }),
          ],
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
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Icon(
                done ? Icons.check_circle : Icons.radio_button_unchecked,
                color: done ? AppColors.primary : AppColors.textGrey,
                size: 18,
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
          _navItem(2, Icons.camera_alt_rounded, 'AI Scan'),
          _navItem(3, Icons.show_chart, 'Báo cáo'),
          _navItem(4, Icons.person, 'Hồ sơ'),
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
