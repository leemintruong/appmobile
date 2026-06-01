import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/app_events.dart';
import '../theme/app_colors.dart';
import '../widgets/sk_ui.dart';
import 'add_meal_screen.dart';
import 'ai_scan_screen.dart';
import 'food_list_screen.dart';
import 'profile_screen.dart';
import 'report_screen.dart';
import 'ai_coach_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _loading = true;
  int _lastEventVersion = 0;
  Timer? _timer;

  Map<String, dynamic> _profile = {};
  Map<String, dynamic> _daily = {};
  Map<String, dynamic> _meals = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastEventVersion = AppEvents.dataVersion.value;
    AppEvents.dataVersion.addListener(_onDataChanged);
    _loadData();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted && _currentIndex == 0) _loadData(silent: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppEvents.dataVersion.removeListener(_onDataChanged);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadData(silent: true);
  }

  void _onDataChanged() {
    if (!mounted) return;
    if (_lastEventVersion != AppEvents.dataVersion.value) {
      _lastEventVersion = AppEvents.dataVersion.value;
      _loadData(silent: true);
    }
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getProfile(),
        ApiService.getDailyReport(date: ApiService.localDateKey()),
        ApiService.getMeals(date: ApiService.localDateKey()),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = ApiService.normalizeObject(results[0]);
        _daily = ApiService.normalizeObject(results[1]);
        _meals = ApiService.normalizeObject(results[2]);
      });
    } catch (e) {
      if (mounted) _toast('Không tải được dữ liệu: $e');
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _openAddMeal() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddMealScreen()),
    );
    if (mounted && result == true) {
      AppEvents.notifyDataChanged();
      await _loadData();
    }
  }

  num _n(dynamic v, {num fallback = 0}) => NumFmt.read(v, fallback: fallback);

  num _read(Map<String, dynamic> root, List<String> keys, {num fallback = 0}) {
    final sources = [
      root,
      root['nutrition'],
      root['goal'],
      root['data'],
      _profile,
      _profile['goal'],
      _meals,
    ];
    for (final src in sources) {
      if (src is Map) {
        for (final k in keys) {
          if (src.containsKey(k)) return _n(src[k], fallback: fallback);
        }
      }
    }
    return fallback;
  }

  List<dynamic> _mealList() =>
      _meals['meals'] is List ? _meals['meals'] as List : [];

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
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : pages[_currentIndex],
      bottomNavigationBar: _bottomBar(),
      floatingActionButton: _floatingActions(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _homePage() {
    final name = (_profile['name'] ?? 'Bạn').toString();
    final goal = _read(_daily, ['daily_calorie_goal'], fallback: 2000);
    final used = _read(_daily, ['total_calories'], fallback: 0);
    final remaining = (goal - used).clamp(0, 99999);
    final protein = _read(_daily, ['total_protein'], fallback: 0);
    final carbs = _read(_daily, ['total_carbs'], fallback: 0);
    final fat = _read(_daily, ['total_fat'], fallback: 0);
    final water = _read(_daily, ['total_water_ml'], fallback: 0);
    final waterGoal = _read(_daily, ['daily_water_goal_ml'], fallback: 2000);
    final burned = _read(_daily, ['total_calories_burned'], fallback: 0);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
          children: [
            SkFadeSlide(child: _header(name)),
            const SizedBox(height: 18),
            SkFadeSlide(
              delayMs: 60,
              child: _calorieCard(used: used, goal: goal, remaining: remaining),
            ),
            const SizedBox(height: 16),
            SkFadeSlide(delayMs: 90, child: _macroGrid(protein, carbs, fat)),
            const SizedBox(height: 16),
            SkFadeSlide(
              delayMs: 110,
              child: _twoStats(water, waterGoal, burned),
            ),
            const SizedBox(height: 16),
            SkFadeSlide(delayMs: 130, child: _mealJournal()),
            const SizedBox(height: 16),
            SkFadeSlide(
              delayMs: 150,
              child: _recommendation(remaining, protein),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(String name) {
    return Row(
      children: [
        const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 28),
        const SizedBox(width: 8),
        const Text(
          'SứcKhỏe',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontSize: 26,
            fontWeight: FontWeight.w900,
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
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              ApiService.localDateKey(),
              style: const TextStyle(color: AppColors.textLight, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _calorieCard({
    required num used,
    required num goal,
    required num remaining,
  }) {
    final percent = goal == 0 ? 0.0 : (used / goal).clamp(0, 1).toDouble();
    return SkCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bạn còn',
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: remaining.toDouble()),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (_, value, __) => Text(
                    '${value.toStringAsFixed(0)} kcal',
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Đã dùng ${used.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)} kcal',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                SkProgressBar(value: percent),
              ],
            ),
          ),
          const SizedBox(width: 18),
          SizedBox(
            width: 92,
            height: 92,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percent),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: v,
                    strokeWidth: 10,
                    color: AppColors.primary,
                    backgroundColor: AppColors.border,
                  ),
                  Text(
                    '${(v * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w900,
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

  Widget _macroGrid(num p, num c, num f) {
    return Row(
      children: [
        Expanded(
          child: _macroChip(
            'Protein',
            p,
            AppColors.protein,
            Icons.fitness_center_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _macroChip('Carbs', c, AppColors.carbs, Icons.grain_rounded),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _macroChip('Fat', f, AppColors.fat, Icons.water_drop_rounded),
        ),
      ],
    );
  }

  Widget _macroChip(String label, num value, Color color, IconData icon) {
    return SkCard(
      padding: const EdgeInsets.all(14),
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(
            '${value.toStringAsFixed(0)}g',
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textGrey,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _twoStats(num water, num waterGoal, num burned) {
    return Row(
      children: [
        Expanded(
          child: _miniStat(
            'Nước uống',
            '${water.toStringAsFixed(0)} ml',
            waterGoal == 0 ? 0 : water / waterGoal,
            Icons.water_drop_rounded,
            AppColors.protein,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _miniStat(
            'Vận động',
            '${burned.toStringAsFixed(0)} kcal',
            .45,
            Icons.directions_walk_rounded,
            AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _miniStat(
    String title,
    String value,
    num percent,
    IconData icon,
    Color color,
  ) {
    return SkCard(
      padding: const EdgeInsets.all(16),
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
          ),
          const SizedBox(height: 10),
          SkProgressBar(
            value: percent.clamp(0, 1).toDouble(),
            color: color,
            height: 7,
          ),
        ],
      ),
    );
  }

  Widget _mealJournal() {
    final meals = _mealList();
    return SkCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Nhật ký hôm nay',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${meals.length} bữa',
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (meals.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  'Chưa có bữa ăn nào hôm nay',
                  style: TextStyle(color: AppColors.textGrey),
                ),
              ),
            )
          else
            ...meals.map((m) => _mealCard(Map<String, dynamic>.from(m as Map))),
        ],
      ),
    );
  }

  Widget _mealCard(Map<String, dynamic> m) {
    final items = m['items'] is List ? m['items'] as List : <dynamic>[];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _mealLabel('${m['meal_type'] ?? ''}'),
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${NumFmt.whole(m['total_calories'])} kcal',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...items.take(3).map((item) {
              final it = Map<String, dynamic>.from(item as Map);
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.restaurant_menu_rounded,
                      size: 14,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${it['food_name'] ?? 'Món ăn'} · ${NumFmt.whole(it['amount'])}${it['amount_unit'] ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      '${NumFmt.whole(it['total_calories'])} kcal',
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
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

  Widget _recommendation(num remaining, num protein) {
    return SkCard(
      color: AppColors.primarySoft,
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              remaining > 500
                  ? 'Bạn còn thiếu ${remaining.toStringAsFixed(0)} kcal. Một bữa phụ giàu protein sẽ giúp đạt mục tiêu.'
                  : 'Hôm nay tiến trình khá ổn. Tiếp tục ghi bữa ăn để báo cáo chính xác hơn.',
              style: const TextStyle(
                color: AppColors.primaryDark,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _mealLabel(String type) {
    switch (type) {
      case 'breakfast':
        return 'Bữa sáng';
      case 'lunch':
        return 'Bữa trưa';
      case 'dinner':
        return 'Bữa tối';
      case 'snack':
        return 'Bữa phụ';
      default:
        return type.isEmpty ? 'Bữa ăn' : type;
    }
  }

  Widget _bottomBar() {
    final items = [
      (Icons.home_rounded, 'Trang chủ'),
      (Icons.restaurant_rounded, 'Thực phẩm'),
      (Icons.camera_alt_rounded, 'AI'),
      (Icons.show_chart_rounded, 'Báo cáo'),
      (Icons.person_rounded, 'Hồ sơ'),
    ];
    return Container(
      height: 74,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final selected = _currentIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _currentIndex = i);
                if (i == 0 || i == 3 || i == 4) _loadData(silent: true);
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primarySoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      items[i].$1,
                      color: selected ? AppColors.primary : AppColors.textLight,
                      size: selected ? 25 : 22,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      items[i].$2,
                      style: TextStyle(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textGrey,
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.w900
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget? _floatingActions() {
    if (_currentIndex == 0) {
      return _PulsingCoachButton(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AiCoachScreen()),
          );
        },
      );
    } else if (_currentIndex == 1) {
      return FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _openAddMeal,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      );
    }
    return null;
  }
}


class _PulsingCoachButton extends StatefulWidget {
  final VoidCallback onTap;

  const _PulsingCoachButton({required this.onTap});

  @override
  State<_PulsingCoachButton> createState() => _PulsingCoachButtonState();
}

class _PulsingCoachButtonState extends State<_PulsingCoachButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = _controller.value;

        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: 1 + pulse * 0.48,
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.18 * (1 - pulse)),
                ),
              ),
            ),
            GestureDetector(
              onTap: widget.onTap,
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primaryDark,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.psychology_alt_rounded,
                  color: Colors.white,
                  size: 31,
                ),
              ),
            ),
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

