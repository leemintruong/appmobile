import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _loadWater();
  }

  Future<void> _loadWater() async {
    setState(() => _loading = true);

    try {
      final data = await ApiService.getWater();
      if (!mounted) return;

      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được nước uống: $e')),
      );
    }
  }

  num _num(dynamic value, [num fallback = 0]) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? fallback;
  }

  List<dynamic> get _logs {
    final logs = _data['logs'];
    return logs is List ? logs : [];
  }

  Future<void> _addWater(int amount) async {
    setState(() => _saving = true);

    try {
      final result = await ApiService.addWater(amount);
      if (!mounted) return;

      if (result['success'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Không lưu được nước uống')),
        );
      } else {
        await _loadWater();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _num(_data['total_water_ml']);
    final goal = _num(_data['daily_water_goal_ml'], 2000);
    final ratio = goal == 0 ? 0.0 : (total / goal).clamp(0, 1).toDouble();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: _loadWater,
                color: AppColors.primary,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                  children: [
                    _header(),
                    const SizedBox(height: 16),
                    _summaryCard(total, goal, ratio),
                    const SizedBox(height: 16),
                    _quickButtons(),
                    const SizedBox(height: 16),
                    _historyCard(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.arrow_back, size: 21),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Theo dõi nước uống',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(num total, num goal, double ratio) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hôm nay', style: TextStyle(color: AppColors.textGrey)),
          const SizedBox(height: 8),
          Text(
            '${total.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)} ml',
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 12,
              backgroundColor: AppColors.background,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thêm nhanh',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [250, 350, 500, 750].map((amount) {
              return ElevatedButton(
                onPressed: _saving ? null : () => _addWater(amount),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primarySoft,
                  foregroundColor: AppColors.primaryDark,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text('+$amount ml'),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _historyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lịch sử hôm nay',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (_logs.isEmpty)
            const Text('Chưa có bản ghi nước uống', style: TextStyle(color: AppColors.textGrey))
          else
            ..._logs.map((item) {
              final map = Map<String, dynamic>.from(item as Map);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.water_drop, color: AppColors.primary),
                title: Text('${_num(map['amount_ml']).toStringAsFixed(0)} ml'),
                subtitle: Text(map['created_at']?.toString() ?? ''),
              );
            }),
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
