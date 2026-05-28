import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/app_events.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _loading = true;
  int _lastEventVersion = 0;

  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic> _daily = {};
  Map<String, dynamic> _weekly = {};

  @override
  void initState() {
    super.initState();
    _lastEventVersion = AppEvents.dataVersion.value;
    AppEvents.dataVersion.addListener(_onDataChanged);
    _loadReport();
  }

  @override
  void dispose() {
    AppEvents.dataVersion.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (!mounted) return;
    if (_lastEventVersion != AppEvents.dataVersion.value) {
      _lastEventVersion = AppEvents.dataVersion.value;
      _loadReport(silent: true);
    }
  }

  Future<void> _loadReport({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);

    try {
      final date = ApiService.formatDateLocal(_selectedDate);
      final start = ApiService.formatDateLocal(_selectedDate.subtract(const Duration(days: 6)));
      final end = date;

      final results = await Future.wait([
        ApiService.getDailyReport(date: date),
        ApiService.getWeeklyReport(start: start, end: end),
      ]);

      if (!mounted) return;

      setState(() {
        _daily = _normalize(results[0]);
        _weekly = _normalize(results[1]);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được báo cáo: $e')),
      );
    }
  }

  Map<String, dynamic> _normalize(dynamic data) => ApiService.normalizeObject(data);

  num _num(dynamic value, {num fallback = 0}) {
    if (value is num) return value;
    if (value != null) {
      final parsed = num.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  num _readNumber(Map<String, dynamic> map, List<String> keys) {
    final sources = <dynamic>[
      map,
      map['nutrition'],
      map['goal'],
      map['average'],
      map['summary'],
      map['data'],
    ];

    for (final source in sources) {
      if (source is Map) {
        for (final key in keys) {
          if (source.containsKey(key)) return _num(source[key]);
        }
      }
    }

    return 0;
  }

  List<dynamic> _weeklyDays() {
    final days = _weekly['days'];
    return days is List ? days : [];
  }

  List<dynamic> _dailyMeals() {
    final meals = _daily['meals'];
    if (meals is List) return meals;

    final details = _daily['meal_details'];
    if (details is List) return details;

    return [];
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'Chọn ngày báo cáo',
    );

    if (picked == null) return;

    setState(() => _selectedDate = picked);
    await _loadReport();
  }

  Future<void> _shiftDay(int delta) async {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: delta));
    });
    await _loadReport();
  }

  @override
  Widget build(BuildContext context) {
    final totalCalories = _readNumber(_daily, ['total_calories', 'calories']);
    final totalProtein = _readNumber(_daily, ['total_protein', 'protein']);
    final totalCarbs = _readNumber(_daily, ['total_carbs', 'carbs']);
    final totalFat = _readNumber(_daily, ['total_fat', 'fat']);
    final goal = _readNumber(_daily, ['daily_calorie_goal']);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: _loadReport,
                color: AppColors.primary,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
                  children: [
                    _topHeader(),
                    const SizedBox(height: 12),
                    _dateSelector(),
                    const SizedBox(height: 16),
                    _summaryCard(totalCalories, goal),
                    const SizedBox(height: 16),
                    _chartCard(),
                    const SizedBox(height: 16),
                    _macroReport(protein: totalProtein, carbs: totalCarbs, fat: totalFat),
                    const SizedBox(height: 16),
                    _mealDetailReport(),
                    const SizedBox(height: 16),
                    _extraStats(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _topHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Báo cáo', style: TextStyle(color: AppColors.textDark, fontSize: 26, fontWeight: FontWeight.w800)),
              SizedBox(height: 4),
              Text('Dữ liệu theo ngày đã chọn', style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
            ],
          ),
        ),
        IconButton(
          onPressed: _loadReport,
          icon: const Icon(Icons.refresh, color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _dateSelector() {
    final text = ApiService.formatDateLocal(_selectedDate);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _shiftDay(-1),
            icon: const Icon(Icons.chevron_left, color: AppColors.primary),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _pickDate,
              child: Column(
                children: [
                  const Text('Ngày báo cáo', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
                  const SizedBox(height: 3),
                  Text(text, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800, fontSize: 16)),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => _shiftDay(1),
            icon: const Icon(Icons.chevron_right, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(num calories, num goal) {
    final percent = goal == 0 ? 0.0 : (calories / goal).clamp(0.0, 1.0).toDouble();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tổng calo ngày đã chọn', style: TextStyle(color: AppColors.textGrey)),
          const SizedBox(height: 8),
          Text('${calories.toStringAsFixed(0)} kcal', style: const TextStyle(color: AppColors.textDark, fontSize: 32, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Mục tiêu: ${goal.toStringAsFixed(0)} kcal', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: percent, minHeight: 10, color: AppColors.primary, backgroundColor: AppColors.border),
          ),
        ],
      ),
    );
  }

  Widget _chartCard() {
    final days = _weeklyDays();
    final maxValue = days.fold<num>(1, (max, item) {
      if (item is Map) {
        final v = num.tryParse('${item['total_calories'] ?? 0}') ?? 0;
        return v > max ? v : max;
      }
      return max;
    });

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Calo 7 ngày gần nhất', style: TextStyle(color: AppColors.textDark, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 18),
          if (days.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('Chưa có dữ liệu tuần', style: TextStyle(color: AppColors.textGrey))),
            )
          else
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: days.map((item) {
                  final map = Map<String, dynamic>.from(item as Map);
                  final value = num.tryParse('${map['total_calories'] ?? 0}') ?? 0;
                  final h = (value / maxValue * 120).clamp(8, 120).toDouble();
                  final label = '${map['log_date'] ?? ''}';
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(value.toStringAsFixed(0), style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
                        const SizedBox(height: 4),
                        Container(width: 22, height: h, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8))),
                        const SizedBox(height: 6),
                        Text(label.length >= 10 ? label.substring(5) : label, style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _macroReport({required num protein, required num carbs, required num fat}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Macro ngày đã chọn', style: TextStyle(color: AppColors.textDark, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          _statRow('Protein', '${protein.toStringAsFixed(0)}g', AppColors.protein),
          _statRow('Carbs', '${carbs.toStringAsFixed(0)}g', AppColors.carbs),
          _statRow('Fat', '${fat.toStringAsFixed(0)}g', AppColors.fat),
        ],
      ),
    );
  }

  Widget _mealDetailReport() {
    final meals = _dailyMeals();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chi tiết bữa ăn', style: TextStyle(color: AppColors.textDark, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (meals.isEmpty)
            const Text('Chưa có bữa ăn trong ngày này.', style: TextStyle(color: AppColors.textGrey))
          else
            ...meals.map((meal) {
              final map = Map<String, dynamic>.from(meal as Map);
              final type = _mealLabel('${map['meal_type'] ?? ''}');
              final kcal = _num(map['total_calories']);
              final items = map['items'] is List ? map['items'] as List : <dynamic>[];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$type · ${kcal.toStringAsFixed(0)} kcal', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    if (items.isEmpty)
                      const Text('Không có chi tiết món.', style: TextStyle(color: AppColors.textGrey, fontSize: 13))
                    else
                      ...items.map((raw) {
                        final item = Map<String, dynamic>.from(raw as Map);
                        final name = '${item['food_name'] ?? item['name'] ?? item['custom_food_name'] ?? 'Món ăn'}';
                        final amount = _num(item['amount'] ?? item['quantity']);
                        final unit = '${item['amount_unit'] ?? item['unit'] ?? ''}';
                        final itemKcal = _num(item['total_calories'] ?? item['calories']);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.restaurant, color: AppColors.primary, size: 16),
                              const SizedBox(width: 7),
                              Expanded(child: Text('$name · ${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 1)}$unit', style: const TextStyle(fontSize: 13, color: AppColors.textDark))),
                              Text('${itemKcal.toStringAsFixed(0)} kcal', style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _extraStats() {
    final water = _readNumber(_daily, ['total_water_ml']);
    final activityMinutes = _readNumber(_daily, ['total_activity_minutes']);
    final burned = _readNumber(_daily, ['total_calories_burned']);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Theo dõi bổ sung', style: TextStyle(color: AppColors.textDark, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          _statRow('Nước uống', '${water.toStringAsFixed(0)} ml', AppColors.protein),
          _statRow('Vận động', '${activityMinutes.toStringAsFixed(0)} phút', AppColors.primary),
          _statRow('Calo tiêu hao', '${burned.toStringAsFixed(0)} kcal', AppColors.warning),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppColors.textGrey)),
          const Spacer(),
          Text(value, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800)),
        ],
      ),
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
        return type.isEmpty ? 'Bữa ăn' : type;
    }
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.035), blurRadius: 20, offset: const Offset(0, 8))],
    );
  }
}
