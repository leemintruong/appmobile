import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  final TextEditingController _weightCtrl = TextEditingController();

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
    setState(() {
      _loading = true;
    });

    try {
      final result = await ApiService.getWeights();

      if (!mounted) return;

      setState(() {
        _weights = result.reversed.toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

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

    setState(() {
      _saving = true;
    });

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
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  double get _currentWeight {
    if (_weights.isEmpty) return 72.4;

    final first = _weights.first;
    return double.tryParse((first['weight_kg'] ?? first['weight']).toString()) ?? 72.4;
  }

  double get _previousWeight {
    if (_weights.length < 2) return _currentWeight;

    final second = _weights[1];
    return double.tryParse((second['weight_kg'] ?? second['weight']).toString()) ?? _currentWeight;
  }

  double get _change {
    return _currentWeight - _previousWeight;
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
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
                  children: [
                    _topHeader(),
                    const SizedBox(height: 16),
                    _currentWeightCard(),
                    const SizedBox(height: 16),
                    _inputCard(),
                    const SizedBox(height: 16),
                    _historyCard(),
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
          'Theo dõi cân nặng',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 24,
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
            Icons.monitor_weight_outlined,
            color: AppColors.primary,
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _currentWeightCard() {
    final change = _change;
    final isDown = change < 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cân nặng hiện tại',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_currentWeight.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isDown
                      ? 'Giảm ${change.abs().toStringAsFixed(1)} kg so với lần trước'
                      : change == 0
                      ? 'Chưa thay đổi so với lần trước'
                      : 'Tăng ${change.abs().toStringAsFixed(1)} kg so với lần trước',
                  style: TextStyle(
                    color: isDown ? AppColors.primary : AppColors.warning,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: 0.62,
                    minHeight: 9,
                    color: AppColors.primary,
                    backgroundColor: AppColors.border,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mục tiêu: 68 kg',
                  style: TextStyle(color: AppColors.textLight, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(42),
            ),
            child: const Center(
              child: Text('⚖️', style: TextStyle(fontSize: 36)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nhập cân nặng mới',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weightCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Ví dụ: 72.4',
              suffixText: 'kg',
              hintStyle: const TextStyle(
                color: AppColors.textLight,
                fontSize: 14,
              ),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveWeight,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : const Text(
                      'Lưu cân nặng',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Lịch sử cân nặng',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${_weights.length} mục',
                style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_weights.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Chưa có dữ liệu cân nặng',
                style: TextStyle(color: AppColors.textGrey),
              ),
            )
          else
            ..._weights.take(6).map((item) {
              return _historyRow(item);
            }),
        ],
      ),
    );
  }

  Widget _historyRow(dynamic item) {
    final weight = item['weight']?.toString() ?? '--';
    final dateRaw = item['log_date']?.toString() ?? '--';
    final date = dateRaw.length >= 10 ? dateRaw.substring(0, 10) : dateRaw;
    final note = item['note']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.monitor_weight_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$weight kg',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  note == null || note.isEmpty ? date : '$date · $note',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
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
