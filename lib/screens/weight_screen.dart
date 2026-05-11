import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});
  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  final _ctrl = TextEditingController();
  List<dynamic> _logs = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadWeights();
  }

  Future<void> _loadWeights() async {
    setState(() => _loading = true);
    final logs = await ApiService.getWeights();
    setState(() {
      _logs = logs.reversed.toList();
      _loading = false;
    });
  }

  Future<void> _save() async {
    final w = double.tryParse(_ctrl.text);
    if (w == null || w <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập cân nặng hợp lệ')),
      );
      return;
    }
    setState(() => _saving = true);
    await ApiService.addWeight(w);
    _ctrl.clear();
    await _loadWeights();
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu cân nặng!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _delete(int id) async {
    await ApiService.deleteWeight(id);
    _loadWeights();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadWeights,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Theo dõi cân nặng',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 20),

              // ── Nhập cân nặng ──────────────────────────
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
                      'Ghi cân nặng hôm nay',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Nhập cân nặng (kg)',
                              suffixText: 'kg',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: AppColors.background,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _saving
                            ? const CircularProgressIndicator(
                                color: AppColors.primary,
                              )
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: _save,
                                child: const Text('Lưu'),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Thay đổi ──────────────────────────────
              if (_logs.length >= 2) _changeCard(),

              const SizedBox(height: 12),
              const Text(
                'Lịch sử',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),

              // ── Danh sách ─────────────────────────────
              _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _logs.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Chưa có dữ liệu.\nHãy ghi cân nặng đầu tiên!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textGrey),
                        ),
                      ),
                    )
                  : Column(
                      children: _logs.map((log) {
                        final id = log['id'] as int;
                        final date = log['log_date'] as String;
                        final w = (log['weight'] as num).toDouble();
                        return Dismissible(
                          key: Key('w_$id'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: AppColors.fat,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (_) => _delete(id),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.monitor_weight_outlined,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      date,
                                      style: const TextStyle(
                                        color: AppColors.textGrey,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '$w kg',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _changeCard() {
    final first = (_logs.last['weight'] as num).toDouble();
    final last = (_logs.first['weight'] as num).toDouble();
    final diff = last - first;
    final isLoss = diff < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (isLoss ? AppColors.primary : AppColors.secondary).withOpacity(
          0.08,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isLoss ? AppColors.primary : AppColors.secondary).withOpacity(
            0.2,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _miniStat('Bắt đầu', '$first kg'),
          const Icon(Icons.arrow_forward, color: AppColors.textGrey, size: 18),
          _miniStat('Hiện tại', '$last kg'),
          _miniStat(
            'Thay đổi',
            '${isLoss ? '' : '+'}${diff.toStringAsFixed(1)} kg',
            color: isLoss ? AppColors.primary : AppColors.secondary,
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, {Color? color}) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: color ?? AppColors.textDark,
        ),
      ),
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
      ),
    ],
  );
}
