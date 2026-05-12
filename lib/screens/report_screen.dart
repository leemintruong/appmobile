import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _loading = true;
  Map<String, dynamic> _daily = {};
  Map<String, dynamic> _weekly = {};

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _loading = true);

    try {
      final daily = await ApiService.getDailyReport();
      final weekly = await ApiService.getWeeklyReport();

      if (!mounted) return;

      setState(() {
        _daily = daily;
        _weekly = weekly;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không tải được báo cáo: $e')));
    }
  }

  num _num(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is num) return value;
    return num.tryParse(value.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final avg = _weekly['average'];
    final avgCalories = avg is Map<String, dynamic>
        ? _num(avg, 'avg_calories')
        : _num(_weekly, 'avg_calories');

    final totalCalories = _num(_daily, 'total_calories');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : RefreshIndicator(
                onRefresh: _loadReport,
                color: AppColors.primary,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                  children: [
                    const Text(
                      'Báo cáo',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Tuần này',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _chartCard(avgCalories),
                    const SizedBox(height: 28),
                    const Text(
                      'Cân nặng',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _weightSummary(),
                    const SizedBox(height: 28),
                    const Text(
                      'Tổng kết',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _summaryCard(totalCalories),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _chartCard(num avgCalories) {
    final bars = [0.62, 0.78, 0.55, 0.92, 0.68, 1.0, 0.75];
    final labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Container(
      height: 190,
      padding: const EdgeInsets.fromLTRB(26, 26, 26, 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 8,
            left: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Calo trung bình',
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${avgCalories.toStringAsFixed(0)} cal',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(bars.length, (index) {
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 26,
                        height: 110 * bars[index],
                        decoration: BoxDecoration(
                          color: const Color(0xFFB8F3D0),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        labels[index],
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weightSummary() {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '65.0 kg',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Giảm 0.6 kg so với tuần trước',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.42,
              minHeight: 10,
              color: AppColors.primary,
              backgroundColor: AppColors.border,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(num totalCalories) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.softGreen2,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFB8F3C8)),
      ),
      child: Text(
        totalCalories > 0
            ? 'Bạn đã ghi nhận ${totalCalories.toStringAsFixed(0)} kcal hôm nay.\nMacro đạt gần mục tiêu, cần duy trì đều hơn.'
            : 'Bạn chưa có dữ liệu calo hôm nay.\nHãy ghi bữa ăn để xem báo cáo chính xác hơn.',
        style: const TextStyle(
          color: Color(0xFF047857),
          fontSize: 15,
          height: 1.6,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
