import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/app_events.dart';
import '../theme/app_colors.dart';
import '../widgets/sk_ui.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _loading = true;
  int _lastEventVersion = 0;
  DateTime _selectedDate = DateTime.now();
  bool _autoPicked = false;
  Map<String, dynamic> _daily = {};
  Map<String, dynamic> _weekly = {};

  @override
  void initState() {
    super.initState();
    _lastEventVersion = AppEvents.dataVersion.value;
    AppEvents.dataVersion.addListener(_onDataChanged);
    _load();
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
      _load(silent: true);
    }
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final end = ApiService.localDateKey(_selectedDate);
      final start = ApiService.localDateKey(_selectedDate.subtract(const Duration(days: 6)));
      var weekly = ApiService.normalizeObject(await ApiService.getWeeklyReport(start: start, end: end));

      if (!_autoPicked) {
        final latest = _latestDateWithData(weekly);
        if (latest != null) {
          _selectedDate = latest;
          final end2 = ApiService.localDateKey(_selectedDate);
          final start2 = ApiService.localDateKey(_selectedDate.subtract(const Duration(days: 6)));
          weekly = ApiService.normalizeObject(await ApiService.getWeeklyReport(start: start2, end: end2));
        }
        _autoPicked = true;
      }

      final daily = ApiService.normalizeObject(await ApiService.getDailyReport(date: ApiService.localDateKey(_selectedDate)));
      if (!mounted) return;
      setState(() {
        _daily = daily;
        _weekly = weekly;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không tải được báo cáo: $e')));
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString();
    return DateTime.tryParse(s.length >= 10 ? s.substring(0, 10) : s);
  }

  DateTime? _latestDateWithData(Map<String, dynamic> weekly) {
    final days = weekly['days'];
    if (days is! List) return null;
    DateTime? latest;
    for (final item in days) {
      if (item is! Map) continue;
      if (NumFmt.read(item['total_calories']) <= 0) continue;
      final d = _parseDate(item['log_date']);
      if (d != null && (latest == null || d.isAfter(latest))) latest = d;
    }
    return latest;
  }

  Future<void> _changeDate(int days) async {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
      _autoPicked = true;
    });
    await _load();
  }

  num _read(List<String> keys) {
    final sources = [_daily, _daily['nutrition'], _daily['goal'], _daily['data']];
    for (final src in sources) {
      if (src is Map) {
        for (final k in keys) {
          if (src.containsKey(k)) return NumFmt.read(src[k]);
        }
      }
    }
    return 0;
  }

  List<dynamic> _days() => _weekly['days'] is List ? _weekly['days'] as List : [];
  List<dynamic> _meals() => _daily['meals'] is List ? _daily['meals'] as List : [];

  @override
  Widget build(BuildContext context) {
    final total = _read(['total_calories']);
    final goal = _read(['daily_calorie_goal']);
    final p = _read(['total_protein']);
    final c = _read(['total_carbs']);
    final f = _read(['total_fat']);

    return SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
                children: [
                  const Text('Báo cáo', style: TextStyle(color: AppColors.textDark, fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  const Text('Theo dõi calo, macro và chi tiết bữa ăn.', style: TextStyle(color: AppColors.textGrey)),
                  const SizedBox(height: 16),
                  SkFadeSlide(child: _dateSelector()),
                  const SizedBox(height: 16),
                  SkFadeSlide(delayMs: 60, child: _summary(total, goal)),
                  const SizedBox(height: 16),
                  SkFadeSlide(delayMs: 90, child: _chart()),
                  const SizedBox(height: 16),
                  SkFadeSlide(delayMs: 110, child: _macro(p, c, f)),
                  const SizedBox(height: 16),
                  SkFadeSlide(delayMs: 130, child: _mealDetails()),
                  const SizedBox(height: 16),
                  SkFadeSlide(delayMs: 150, child: _extra()),
                ],
              ),
            ),
    );
  }

  Widget _dateSelector() {
    return SkCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: [
        IconButton(onPressed: () => _changeDate(-1), icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primary)),
        Expanded(child: Column(children: [
          const Text('Ngày đang xem', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(ApiService.localDateKey(_selectedDate), style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w900, fontSize: 17)),
        ])),
        IconButton(onPressed: () => _changeDate(1), icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primary)),
      ]),
    );
  }

  Widget _summary(num calories, num goal) {
    final pct = goal == 0 ? 0.0 : (calories / goal).clamp(0, 1).toDouble();
    return SkCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Tổng calo ngày đã chọn', style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('${calories.toStringAsFixed(0)} kcal', style: const TextStyle(color: AppColors.textDark, fontSize: 34, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('Mục tiêu: ${goal.toStringAsFixed(0)} kcal', style: const TextStyle(color: AppColors.textLight)),
        const SizedBox(height: 14),
        SkProgressBar(value: pct),
      ]),
    );
  }

  Widget _chart() {
    final days = _days();
    final max = days.fold<num>(1, (m, item) => item is Map && NumFmt.read(item['total_calories']) > m ? NumFmt.read(item['total_calories']) : m);
    return SkCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Calo 7 ngày gần nhất', style: TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 18),
        if (days.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Chưa có dữ liệu tuần', style: TextStyle(color: AppColors.textGrey))))
        else
          SizedBox(
            height: 190,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: days.map((item) {
              final m = Map<String, dynamic>.from(item as Map);
              final value = NumFmt.read(m['total_calories']);
              final d = _parseDate(m['log_date']);
              final selected = d != null && ApiService.localDateKey(d) == ApiService.localDateKey(_selectedDate);
              final h = value <= 0 ? 8.0 : (value / max * 118).clamp(12, 118).toDouble();
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: d == null ? null : () async { setState(() { _selectedDate = d; _autoPicked = true; }); await _load(); },
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Text(value.toStringAsFixed(0), style: TextStyle(color: selected ? AppColors.primaryDark : AppColors.textGrey, fontSize: 10, fontWeight: selected ? FontWeight.w900 : FontWeight.w600)),
                    const SizedBox(height: 5),
                    AnimatedContainer(duration: const Duration(milliseconds: 250), width: selected ? 30 : 22, height: h, decoration: BoxDecoration(color: selected ? AppColors.primaryDark : AppColors.primary, borderRadius: BorderRadius.circular(9))),
                    const SizedBox(height: 7),
                    Text(d == null ? '' : '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}', style: TextStyle(color: selected ? AppColors.primaryDark : AppColors.textGrey, fontSize: 10, fontWeight: selected ? FontWeight.w900 : FontWeight.w600)),
                  ]),
                ),
              );
            }).toList()),
          ),
      ]),
    );
  }

  Widget _macro(num p, num c, num f) {
    return SkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Macro ngày đã chọn', style: TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12),
      _stat('Protein', '${p.toStringAsFixed(0)}g', AppColors.protein),
      _stat('Carbs', '${c.toStringAsFixed(0)}g', AppColors.carbs),
      _stat('Fat', '${f.toStringAsFixed(0)}g', AppColors.fat),
    ]));
  }

  Widget _mealDetails() {
    final meals = _meals();
    return SkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Chi tiết bữa ăn', style: TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12),
      if (meals.isEmpty)
        const Text('Chưa có bữa ăn trong ngày này.', style: TextStyle(color: AppColors.textGrey))
      else
        ...meals.map((meal) => _mealBlock(Map<String, dynamic>.from(meal as Map))),
    ]));
  }

  Widget _mealBlock(Map<String, dynamic> m) {
    final items = m['items'] is List ? m['items'] as List : <dynamic>[];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(_mealLabel('${m['meal_type'] ?? ''}'), style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w900))),
          Text('${NumFmt.whole(m['total_calories'])} kcal', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 4),
        Text('P ${NumFmt.whole(m['total_protein'])}g · C ${NumFmt.whole(m['total_carbs'])}g · F ${NumFmt.whole(m['total_fat'])}g', style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
        const SizedBox(height: 8),
        ...items.map((item) {
          final it = Map<String, dynamic>.from(item as Map);
          return Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(children: [
              const Icon(Icons.restaurant_menu_rounded, size: 14, color: AppColors.textLight),
              const SizedBox(width: 6),
              Expanded(child: Text('${it['food_name'] ?? it['custom_food_name'] ?? 'Món ăn'} · ${NumFmt.whole(it['amount'])}${it['amount_unit'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textGrey, fontSize: 12))),
              Text('${NumFmt.whole(it['total_calories'])} kcal', style: const TextStyle(color: AppColors.textDark, fontSize: 12, fontWeight: FontWeight.w800)),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _extra() {
    return SkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Theo dõi bổ sung', style: TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12),
      _stat('Nước uống', '${_read(['total_water_ml']).toStringAsFixed(0)} ml', AppColors.protein),
      _stat('Vận động', '${_read(['total_activity_minutes']).toStringAsFixed(0)} phút', AppColors.primary),
      _stat('Calo tiêu hao', '${_read(['total_calories_burned']).toStringAsFixed(0)} kcal', AppColors.warning),
    ]));
  }

  Widget _stat(String label, String value, Color color) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.w700)),
      const Spacer(),
      Text(value, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w900)),
    ]));
  }

  String _mealLabel(String type) {
    switch (type) {
      case 'breakfast': return 'Bữa sáng';
      case 'lunch': return 'Bữa trưa';
      case 'dinner': return 'Bữa tối';
      case 'snack': return 'Bữa phụ';
      default: return type.isEmpty ? 'Bữa ăn' : type;
    }
  }
}
