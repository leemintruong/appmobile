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
  int _tab = 0;

  // Dữ liệu từ API
  Map<String, dynamic> _profile = {};
  Map<String, dynamic> _dailyReport = {};
  List<dynamic> _meals = [];
  bool _loading = true;

  // Mục tiêu mặc định nếu chưa có
  double get _goalCalories =>
      (_profile['daily_calorie_goal'] ?? 1500).toDouble();
  double get _goalProtein => (_profile['daily_protein_goal'] ?? 80).toDouble();
  double get _goalCarbs => (_profile['daily_carbs_goal'] ?? 180).toDouble();
  double get _goalFat => (_profile['daily_fat_goal'] ?? 50).toDouble();

  // Tổng thực tế từ API
  double get _totalCalories =>
      (_dailyReport['nutrition']?['total_calories'] ?? 0).toDouble();
  double get _totalProtein =>
      (_dailyReport['nutrition']?['total_protein'] ?? 0).toDouble();
  double get _totalCarbs =>
      (_dailyReport['nutrition']?['total_carbs'] ?? 0).toDouble();
  double get _totalFat =>
      (_dailyReport['nutrition']?['total_fat'] ?? 0).toDouble();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getProfile(),
        ApiService.getDailyReport(),
        ApiService.getMeals(),
      ]);
      setState(() {
        _profile = results[0];
        _dailyReport = results[1];
        final mealData = results[2];
        _meals = mealData['meals'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _loading ? _loadingPage() : _homePage(),
      const ReportScreen(),
      const WeightScreen(),
      ProfileScreen(profile: _profile),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.white,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Báo cáo',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_weight_outlined),
            selectedIcon: Icon(Icons.monitor_weight),
            label: 'Cân nặng',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }

  Widget _loadingPage() =>
      const Center(child: CircularProgressIndicator(color: AppColors.primary));

  Widget _homePage() {
    final now = DateTime.now();
    final days = [
      'Chủ nhật',
      'Thứ hai',
      'Thứ ba',
      'Thứ tư',
      'Thứ năm',
      'Thứ sáu',
      'Thứ bảy',
    ];
    final name = _profile['name'] ?? 'Bạn';

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xin chào, $name! 👋',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        '${days[now.weekday % 7]}, '
                        '${now.day}/${now.month}/${now.year}',
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Calo card ───────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'CALO HÔM NAY',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_totalCalories.round()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ' / ${_goalCalories.round()} kcal',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_totalCalories / _goalCalories).clamp(0.0, 1.0),
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Còn lại '
                      '${(_goalCalories - _totalCalories).round()} kcal',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Macro card ──────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MACRO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textGrey,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _macroRow(
                      'Protein',
                      _totalProtein,
                      _goalProtein,
                      AppColors.protein,
                    ),
                    const SizedBox(height: 10),
                    _macroRow(
                      'Carbs',
                      _totalCarbs,
                      _goalCarbs,
                      AppColors.carbs,
                    ),
                    const SizedBox(height: 10),
                    _macroRow('Fat', _totalFat, _goalFat, AppColors.fat),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Danh sách bữa ───────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'BỮA ĂN HÔM NAY',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textGrey,
                      letterSpacing: 1,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _openAddMeal,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Thêm'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),

              ..._meals.map((m) => _mealCard(m)),
              const SizedBox(height: 8),
              _addMealButton(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAddMeal() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddMealScreen()),
    );
    if (saved == true) _loadData(); // reload sau khi thêm
  }

  Widget _macroRow(String label, double val, double goal, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textDark),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (val / goal).clamp(0.0, 1.0),
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${val.round()}g',
          style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
        ),
      ],
    );
  }

  Widget _mealCard(Map<String, dynamic> meal) {
    final items = (meal['items'] as List?) ?? [];
    final typeLabel = _mealLabel(meal['meal_type']);
    final typeEmoji = _mealEmoji(meal['meal_type']);
    final totalCal = (meal['total_calories'] ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Text(typeEmoji, style: const TextStyle(fontSize: 24)),
          title: Text(
            typeLabel,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Text(
            '${totalCal.round()} kcal',
            style: const TextStyle(color: AppColors.primary, fontSize: 13),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.textGrey,
                  size: 20,
                ),
                onPressed: () => _deleteMeal(meal['meal_log_id']),
              ),
              const Icon(Icons.expand_more),
            ],
          ),
          children: items
              .map<Widget>(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '• ${item['food_name']}  '
                          '${item['quantity'].round()}'
                          '${item['serving_unit']}',
                          style: const TextStyle(color: AppColors.textDark),
                        ),
                      ),
                      Text(
                        '${(item['total_calories'] as num).round()} kcal',
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Future<void> _deleteMeal(int mealLogId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa bữa ăn?'),
        content: const Text('Bạn có chắc muốn xóa bữa ăn này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.fat,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService.deleteMeal(mealLogId);
      _loadData();
    }
  }

  Widget _addMealButton() {
    final existing = _meals.map((m) => m['meal_type']).toSet();
    final remaining = [
      'breakfast',
      'lunch',
      'dinner',
      'snack',
    ].where((t) => !existing.contains(t)).toList();
    if (remaining.isEmpty) return const SizedBox();

    return GestureDetector(
      onTap: _openAddMeal,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Thêm bữa ăn',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _mealLabel(String? type) {
    switch (type) {
      case 'breakfast':
        return 'Bữa sáng';
      case 'lunch':
        return 'Bữa trưa';
      case 'dinner':
        return 'Bữa tối';
      default:
        return 'Bữa phụ';
    }
  }

  String _mealEmoji(String? type) {
    switch (type) {
      case 'breakfast':
        return '🌅';
      case 'lunch':
        return '☀️';
      case 'dinner':
        return '🌙';
      default:
        return '🍎';
    }
  }
}
