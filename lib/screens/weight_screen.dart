import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  final _weightCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  List<dynamic> _weights = [];

  @override
  void initState() {
    super.initState();
    _loadWeights();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWeights() async {
    setState(() => _loading = true);

    try {
      final weights = await ApiService.getWeights();

      if (!mounted) return;

      setState(() {
        _weights = weights.reversed.toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không tải được cân nặng: $e')));
    }
  }

  Future<void> _saveWeight() async {
    final weight = double.tryParse(_weightCtrl.text.trim());

    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập cân nặng hợp lệ')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final result = await ApiService.addWeight(weight);

      if (!mounted) return;

      if (result['success'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Không lưu được cân nặng'),
          ),
        );
        return;
      }

      _weightCtrl.clear();
      await _loadWeights();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  double get _currentWeight {
    if (_weights.isEmpty) return 65.0;
    final first = _weights.first;
    return double.tryParse(first['weight'].toString()) ?? 65.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : RefreshIndicator(
                onRefresh: _loadWeights,
                color: AppColors.primary,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                  children: [
                    const Text(
                      'Theo dõi cân nặng',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 44),
                    _currentWeightCard(),
                    const SizedBox(height: 28),
                    const Text(
                      'Nhập cân nặng mới',
                      style: TextStyle(
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        hintText: '64.8',
                        hintStyle: const TextStyle(color: AppColors.textLight),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.6),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.inputBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.inputBorder,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 58,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveWeight,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _saving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Lưu cân nặng',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 34),
                    const Text(
                      'Lịch sử gần đây',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_weights.isEmpty)
                      const Text(
                        'Chưa có lịch sử cân nặng',
                        style: TextStyle(color: AppColors.textGrey),
                      )
                    else
                      ..._weights.take(5).map((w) => _historyCard(w)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _currentWeightCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.62),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cân nặng hiện tại',
            style: TextStyle(
              color: AppColors.textGrey,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${_currentWeight.toStringAsFixed(1)} kg',
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 44,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Mục tiêu: 60 kg',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyCard(dynamic item) {
    final date = item['log_date']?.toString().substring(0, 10) ?? '--';
    final weight = item['weight']?.toString() ?? '--';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.62),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              date,
              style: const TextStyle(
                color: AppColors.textGrey,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '$weight kg',
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
