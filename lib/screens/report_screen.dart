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
        _daily = _normalize(daily);
        _weekly = _normalize(weekly);
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

  Map<String, dynamic> _normalize(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['data'] is Map<String, dynamic>) return data['data'];
      if (data['report'] is Map<String, dynamic>) return data['report'];
      return data;
    }

    return {};
  }

  num _readNumber(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];

      if (value is num) return value;

      if (value != null) {
        final parsed = num.tryParse(value.toString());
        if (parsed != null) return parsed;
      }
    }

    final nutrition = map['nutrition'];
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

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final totalCalories = _readNumber(_daily, ['total_calories', 'calories']);
    final totalProtein = _readNumber(_daily, ['total_protein', 'protein']);
    final totalCarbs = _readNumber(_daily, ['total_carbs', 'carbs']);
    final totalFat = _readNumber(_daily, ['total_fat', 'fat']);

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
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
                  children: [
                    _topHeader(),
                    const SizedBox(height: 16),
                    _summaryCard(totalCalories),
                    const SizedBox(height: 16),
                    _chartCard(),
                    const SizedBox(height: 16),
                    _macroReport(
                      protein: totalProtein,
                      carbs: totalCarbs,
                      fat: totalFat,
                    ),
                    const SizedBox(height: 16),
                    _aiInsightCard(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _topHeader() {
    return Row(
      children: [
        const Text(
          'Báo cáo',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(
            Icons.calendar_today,
            color: AppColors.textDark,
            size: 19,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(num totalCalories) {
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
                  'Tổng năng lượng hôm nay',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '${totalCalories.toStringAsFixed(0)} kcal',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Dữ liệu được tổng hợp từ nhật ký bữa ăn',
                  style: TextStyle(color: AppColors.textLight, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(38),
            ),
            child: const Center(
              child: Text('📈', style: TextStyle(fontSize: 34)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartCard() {
    final bars = [0.55, 0.75, 0.68, 0.9, 0.62, 1.0, 0.82];
    final labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Container(
      height: 230,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calo trong tuần',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Biểu đồ tiêu thụ năng lượng theo ngày',
            style: TextStyle(color: AppColors.textGrey, fontSize: 13),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(bars.length, (index) {
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 24,
                      height: 110 * bars[index],
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      labels[index],
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _macroReport({
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
          const Text(
            'Phân tích macro',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          _macroLine(
            'Protein',
            '${protein.toStringAsFixed(0)}g',
            AppColors.primary,
            0.35,
          ),
          const SizedBox(height: 16),
          _macroLine(
            'Carbs',
            '${carbs.toStringAsFixed(0)}g',
            AppColors.protein,
            0.50,
          ),
          const SizedBox(height: 16),
          _macroLine(
            'Fat',
            '${fat.toStringAsFixed(0)}g',
            AppColors.warning,
            0.25,
          ),
        ],
      ),
    );
  }

  Widget _macroLine(String label, String value, Color color, double percent) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
              ),
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

  Widget _aiInsightCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💡', style: TextStyle(fontSize: 28)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Gợi ý hôm nay: Bạn nên bổ sung thêm protein và duy trì ghi bữa ăn đều đặn để báo cáo chính xác hơn.',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
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
}
