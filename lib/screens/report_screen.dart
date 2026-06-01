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
  bool _autoSelectedLatestData = false;

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

  String _dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _shortDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString();
    if (s.length >= 10) {
      return DateTime.tryParse(s.substring(0, 10));
    }
    return DateTime.tryParse(s);
  }

  Future<void> _loadReport({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);

    try {
      final end = _dateKey(_selectedDate);
      final start = _dateKey(_selectedDate.subtract(const Duration(days: 6)));

      final weeklyData = await ApiService.getWeeklyReport(start: start, end: end);
      Map<String, dynamic> weekly = _normalize(weeklyData);

      if (!_autoSelectedLatestData) {
        final latest = _latestDateWithData(weekly);
        if (latest != null && _dateKey(latest) != _dateKey(_selectedDate)) {
          _selectedDate = latest;
          _autoSelectedLatestData = true;
          final newEnd = _dateKey(_selectedDate);
          final newStart = _dateKey(_selectedDate.subtract(const Duration(days: 6)));
          weekly = _normalize(await ApiService.getWeeklyReport(start: newStart, end: newEnd));
        } else {
          _autoSelectedLatestData = true;
        }
      }

      final dailyData = await ApiService.getDailyReport(date: _dateKey(_selectedDate));

      if (!mounted) return;

      setState(() {
        _daily = _normalize(dailyData);
        _weekly = weekly;
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

  DateTime? _latestDateWithData(Map<String, dynamic> weekly) {
    final days = weekly['days'];
    if (days is! List) return null;

    DateTime? latest;

    for (final item in days) {
      if (item is! Map) continue;
      final calories = _num(item['total_calories']);
      if (calories <= 0) continue;
      final date = _parseDate(item['log_date']);
      if (date == null) continue;
      if (latest == null || date.isAfter(latest)) latest = date;
    }

    return latest;
  }

  Future<void> _changeDate(int delta) async {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: delta));
      _autoSelectedLatestData = true;
    });
    await _loadReport();
  }

  Map<String, dynamic> _normalize(dynamic data) => ApiService.normalizeObject(data);

  num _num(dynamic v, {num fallback = 0}) {
    if (v is num) return v;
    if (v != null) return num.tryParse(v.toString()) ?? fallback;
    return fallback;
  }

  num _readNumber(Map<String, dynamic> map, List<String> keys) {
    final sources = [
      map,
      map['nutrition'],
      map['goal'],
      map['average'],
      map['data'],
      map['report'],
    ];

    for (final source in sources) {
      if (source is Map) {
        for (final key in keys) {
          if (source.containsKey(key)) {
            return _num(source[key]);
          }
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
    return meals is List ? meals : [];
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
                    const SizedBox(height: 14),
                    _dateSelector(),
                    const SizedBox(height: 16),
                    _summaryCard(totalCalories, goal),
                    const SizedBox(height: 16),
                    _chartCard(),
                    const SizedBox(height: 16),
                    _macroReport(protein: totalProtein, carbs: totalCarbs, fat: totalFat),
                    const SizedBox(height: 16),
                    _mealDetailsCard(),
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
              Text('Chạm vào cột trong biểu đồ để xem chi tiết ngày đó', style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _changeDate(-1),
            icon: const Icon(Icons.chevron_left, color: AppColors.primary),
          ),
          Expanded(
            child: Column(
              children: [
                const Text('Ngày đang xem', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
                const SizedBox(height: 3),
                Text(
                  _dateKey(_selectedDate),
                  style: const TextStyle(color: AppColors.textDark, fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _changeDate(1),
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
        final v = _num(item['total_calories']);
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
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: days.map((item) {
                  final map = Map<String, dynamic>.from(item as Map);
                  final value = _num(map['total_calories']);
                  final h = value <= 0 ? 8.0 : (value / maxValue * 120).clamp(12, 120).toDouble();
                  final date = _parseDate(map['log_date']);
                  final selected = date != null && _dateKey(date) == _dateKey(_selectedDate);

                  return Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: date == null
                          ? null
                          : () async {
                              setState(() {
                                _selectedDate = date;
                                _autoSelectedLatestData = true;
                              });
                              await _loadReport();
                            },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(value.toStringAsFixed(0), style: TextStyle(fontSize: 10, color: selected ? AppColors.primary : AppColors.textGrey, fontWeight: selected ? FontWeight.w800 : FontWeight.w400)),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: selected ? 28 : 22,
                            height: h,
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primaryDark : AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(date == null ? '' : _shortDate(date), style: TextStyle(fontSize: 10, color: selected ? AppColors.primaryDark : AppColors.textGrey, fontWeight: selected ? FontWeight.w800 : FontWeight.w400)),
                        ],
                      ),
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

  Widget _mealDetailsCard() {
    final meals = _dailyMeals();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chi tiết bữa ăn', style: TextStyle(color: AppColors.textDark, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          if (meals.isEmpty)
            const Text('Chưa có bữa ăn trong ngày này.', style: TextStyle(color: AppColors.textGrey))
          else
            ...meals.map((meal) {
              final m = Map<String, dynamic>.from(meal as Map);
              final items = m['items'] is List ? m['items'] as List : <dynamic>[];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _mealLabel('${m['meal_type'] ?? ''}'),
                      style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_num(m['total_calories']).toStringAsFixed(0)} kcal · P ${_num(m['total_protein']).toStringAsFixed(0)}g · C ${_num(m['total_carbs']).toStringAsFixed(0)}g · F ${_num(m['total_fat']).toStringAsFixed(0)}g',
                      style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                    ),
                    if (items.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...items.map((item) {
                        final it = Map<String, dynamic>.from(item as Map);
                        final name = it['food_name'] ?? it['custom_food_name'] ?? 'Món ăn';
                        final amount = _num(it['amount']).toStringAsFixed(0);
                        final unit = it['amount_unit'] ?? '';
                        final kcal = _num(it['total_calories'] ?? it['calories']).toStringAsFixed(0);
                        return Padding(
                          padding: const EdgeInsets.only(top: 5),
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
                              Text('$kcal kcal', style: const TextStyle(color: AppColors.textDark, fontSize: 12, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        );
                      }),
                    ],
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.035), blurRadius: 20, offset: const Offset(0, 8))],
    );
  }
}
