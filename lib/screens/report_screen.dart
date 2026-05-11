import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int _period = 1; // 0=Ngày, 1=Tuần, 2=Tháng
  bool _loading = true;

  Map<String, dynamic> _daily = {};
  Map<String, dynamic> _weekly = {};
  Map<String, dynamic> _monthly = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getDailyReport(),
        ApiService.getWeeklyReport(),
        ApiService.getMonthlyReport(),
      ]);
      setState(() {
        _daily = results[0];
        _weekly = results[1];
        _monthly = results[2];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadAll,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Báo cáo tiến trình',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _periodTab(),
                    const SizedBox(height: 20),
                    if (_period == 0) _dailyView(),
                    if (_period == 1) _weeklyView(),
                    if (_period == 2) _monthlyView(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _periodTab() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: ['Ngày', 'Tuần', 'Tháng']
          .asMap()
          .entries
          .map(
            (e) => Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _period = e.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _period == e.key
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    e.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _period == e.key
                          ? Colors.white
                          : AppColors.textGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    ),
  );

  // ── Ngày ──────────────────────────────────────────────────
  Widget _dailyView() {
    final nutrition = _daily['nutrition'];
    final goal = _daily['goal'];
    if (nutrition == null) {
      return _emptyCard('Chưa có dữ liệu hôm nay.\nHãy ghi bữa ăn đầu tiên!');
    }
    final cal = (nutrition['total_calories'] ?? 0).toDouble();
    final pro = (nutrition['total_protein'] ?? 0).toDouble();
    final carb = (nutrition['total_carbs'] ?? 0).toDouble();
    final fat = (nutrition['total_fat'] ?? 0).toDouble();
    final gcal = (goal?['daily_calorie_goal'] ?? 1500).toDouble();
    final gpro = (goal?['daily_protein_goal'] ?? 80).toDouble();
    final gcarb = (goal?['daily_carbs_goal'] ?? 180).toDouble();
    final gfat = (goal?['daily_fat_goal'] ?? 50).toDouble();

    return Column(
      children: [
        Row(
          children: [
            _statCard(
              'Calo',
              '${cal.round()}',
              'kcal',
              AppColors.secondary,
              Icons.local_fire_department,
            ),
            const SizedBox(width: 12),
            _statCard(
              'Đạt',
              '${(cal / gcal * 100).round()}%',
              'mục tiêu',
              AppColors.primary,
              Icons.check_circle_outline,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _macroCard(pro, gpro, carb, gcarb, fat, gfat),
      ],
    );
  }

  // ── Tuần ──────────────────────────────────────────────────
  Widget _weeklyView() {
    final days = (_weekly['days'] as List?) ?? [];
    final avg = _weekly['average'] as Map<String, dynamic>?;

    return Column(
      children: [
        if (avg != null)
          Row(
            children: [
              _statCard(
                'Calo TB',
                '${avg['avg_calories']}',
                'kcal/ngày',
                AppColors.secondary,
                Icons.local_fire_department,
              ),
              const SizedBox(width: 12),
              _statCard(
                'Protein TB',
                '${avg['avg_protein']}g',
                'mỗi ngày',
                AppColors.protein,
                Icons.fitness_center,
              ),
            ],
          ),
        const SizedBox(height: 16),
        _calorieBarChart(days),
      ],
    );
  }

  // ── Tháng ─────────────────────────────────────────────────
  Widget _monthlyView() {
    final weights = (_monthly['weights'] as List?) ?? [];

    return Column(
      children: [
        _weeklyView(), // dùng lại biểu đồ calo tuần
        const SizedBox(height: 16),
        _weightCard(weights),
      ],
    );
  }

  Widget _calorieBarChart(List days) {
    if (days.isEmpty) return _emptyCard('Chưa có dữ liệu tuần này');

    final maxCal = days.fold<double>(
      0,
      (m, d) => ((d['total_calories'] ?? 0) as num).toDouble() > m
          ? ((d['total_calories'] ?? 0) as num).toDouble()
          : m,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calo theo ngày',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map<Widget>((d) {
                final val = (d['total_calories'] ?? 0 as num).toDouble();
                final ratio = maxCal > 0 ? (val / maxCal).clamp(0.0, 1.0) : 0.0;
                final dateStr = (d['log_date'] as String).substring(5); // MM-DD
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (val > 0)
                          Text(
                            '${val.round()}',
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textGrey,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Container(
                          height: (120 * ratio).toDouble(),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textGrey,
                          ),
                        ),
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

  Widget _weightCard(List weights) {
    if (weights.isEmpty) {
      return _emptyCard('Chưa có dữ liệu cân nặng tháng này');
    }
    final first = (weights.first['weight'] as num).toDouble();
    final last = (weights.last['weight'] as num).toDouble();
    final diff = (last - first);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tiến trình cân nặng',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _weightStat('Bắt đầu', '$first kg'),
              _weightStat('Hiện tại', '$last kg'),
              _weightStat(
                'Thay đổi',
                '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)} kg',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (diff < 0 ? AppColors.primary : AppColors.secondary)
                  .withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  diff < 0 ? '📉' : '📈',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  diff < 0
                      ? 'Giảm ${(-diff).toStringAsFixed(1)} kg tháng này'
                      : 'Tăng ${diff.toStringAsFixed(1)} kg tháng này',
                  style: TextStyle(
                    color: diff < 0 ? AppColors.primary : AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroCard(
    double pro,
    double gpro,
    double carb,
    double gcarb,
    double fat,
    double gfat,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phân bổ Macro',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          _macroRow('Protein', pro, gpro, AppColors.protein),
          const SizedBox(height: 10),
          _macroRow('Carbs', carb, gcarb, AppColors.carbs),
          const SizedBox(height: 10),
          _macroRow('Fat', fat, gfat, AppColors.fat),
        ],
      ),
    );
  }

  Widget _macroRow(String label, double val, double goal, Color color) => Row(
    children: [
      SizedBox(
        width: 60,
        child: Text(label, style: const TextStyle(fontSize: 13)),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (val / goal).clamp(0.0, 1.0),
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 10,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        '${val.round()}/${goal.round()}g',
        style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
      ),
    ],
  );

  Widget _statCard(
    String title,
    String value,
    String sub,
    Color color,
    IconData icon,
  ) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            sub,
            style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _weightStat(String label, String value) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
      ),
    ],
  );

  Widget _emptyCard(String msg) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Center(
      child: Text(
        msg,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textGrey),
      ),
    ),
  );
}
