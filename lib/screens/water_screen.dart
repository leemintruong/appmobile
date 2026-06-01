import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/app_events.dart';
import '../theme/app_colors.dart';
import '../widgets/sk_ui.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  bool _loading = true;
  Map<String, dynamic> _data = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { final data = await ApiService.getWater(date: ApiService.localDateKey()); if (mounted) setState(() => _data = data); } catch (e) { if (mounted) _toast('Không tải được nước uống: $e'); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _add(int ml) async {
    final result = await ApiService.addWater(ml, date: ApiService.localDateKey());
    if (result['success'] == true) { AppEvents.notifyDataChanged(); _load(); } else { _toast(result['message'] ?? 'Không lưu được nước uống'); }
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final water = NumFmt.read(_data['total_water_ml']);
    final goal = NumFmt.read(_data['daily_water_goal_ml'], fallback: 2000);
    final logs = _data['logs'] is List ? _data['logs'] as List : [];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 30), children: [
          Row(children: [IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)), const Expanded(child: Text('Theo dõi nước uống', style: TextStyle(color: AppColors.textDark, fontSize: 24, fontWeight: FontWeight.w900)))]),
          const SizedBox(height: 12),
          if (_loading) const Center(child: CircularProgressIndicator(color: AppColors.primary)) else ...[
            SkCard(color: AppColors.primarySoft, child: Column(children: [
              const Icon(Icons.water_drop_rounded, color: AppColors.protein, size: 62),
              const SizedBox(height: 12),
              Text('${water.toStringAsFixed(0)} ml', style: const TextStyle(color: AppColors.textDark, fontSize: 32, fontWeight: FontWeight.w900)),
              Text('Mục tiêu ${goal.toStringAsFixed(0)} ml', style: const TextStyle(color: AppColors.textGrey)),
              const SizedBox(height: 16),
              SkProgressBar(value: goal == 0 ? 0 : water / goal, color: AppColors.protein, height: 12),
            ])),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: SkPrimaryButton(label: '+250 ml', onPressed: () => _add(250))),
              const SizedBox(width: 10),
              Expanded(child: SkPrimaryButton(label: '+500 ml', onPressed: () => _add(500))),
            ]),
            const SizedBox(height: 16),
            SkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Lịch sử hôm nay', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 10),
              if (logs.isEmpty) const Text('Chưa có dữ liệu', style: TextStyle(color: AppColors.textGrey))
              else ...logs.map((x) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.water_drop, color: AppColors.protein), title: Text('${NumFmt.whole((x as Map)['amount_ml'])} ml'), subtitle: Text('${x['created_at'] ?? ''}'))),
            ])),
          ]
        ]),
      ),
    );
  }
}
