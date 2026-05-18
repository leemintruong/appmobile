import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final _nameCtrl = TextEditingController(text: 'Đi bộ nhanh');
  final _durationCtrl = TextEditingController(text: '30');
  final _caloriesCtrl = TextEditingController(text: '120');

  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _durationCtrl.dispose();
    _caloriesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    setState(() => _loading = true);

    try {
      final data = await ApiService.getActivities();
      if (!mounted) return;

      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được vận động: $e')),
      );
    }
  }

  num _num(dynamic value, [num fallback = 0]) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? fallback;
  }

  List<dynamic> get _activities {
    final data = _data['activities'];
    return data is List ? data : [];
  }

  Future<void> _saveActivity() async {
    final name = _nameCtrl.text.trim();
    final duration = int.tryParse(_durationCtrl.text.trim());
    final calories = double.tryParse(_caloriesCtrl.text.trim()) ?? 0;

    if (name.isEmpty || duration == null || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập hoạt động hợp lệ')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final result = await ApiService.addActivity(
        activityName: name,
        durationMinutes: duration,
        caloriesBurned: calories,
      );

      if (!mounted) return;

      if (result['success'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Không lưu được vận động')),
        );
      } else {
        await _loadActivities();
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
    final minutes = _num(_data['total_activity_minutes']);
    final burned = _num(_data['total_calories_burned']);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: _loadActivities,
                color: AppColors.primary,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                  children: [
                    _header(),
                    const SizedBox(height: 16),
                    _summaryCard(minutes, burned),
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
            'Theo dõi vận động',
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

  Widget _summaryCard(num minutes, num burned) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(child: _metric('Thời gian', '${minutes.toStringAsFixed(0)} phút')),
          Container(width: 1, height: 54, color: AppColors.border),
          Expanded(child: _metric('Đốt cháy', '${burned.toStringAsFixed(0)} kcal')),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textGrey)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _inputCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thêm hoạt động',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _input(_nameCtrl, 'Tên hoạt động'),
          const SizedBox(height: 10),
          _input(_durationCtrl, 'Thời gian/phút', keyboardType: TextInputType.number),
          const SizedBox(height: 10),
          _input(_caloriesCtrl, 'Calo tiêu hao', keyboardType: TextInputType.number),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveActivity,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: Text(_saving ? 'Đang lưu...' : 'Lưu hoạt động'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(TextEditingController controller, String label, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
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
          if (_activities.isEmpty)
            const Text('Chưa có hoạt động nào', style: TextStyle(color: AppColors.textGrey))
          else
            ..._activities.map((item) {
              final map = Map<String, dynamic>.from(item as Map);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.directions_walk, color: AppColors.primary),
                title: Text(map['activity_name']?.toString() ?? 'Hoạt động'),
                subtitle: Text('${_num(map['duration_minutes']).toStringAsFixed(0)} phút'),
                trailing: Text('${_num(map['calories_burned']).toStringAsFixed(0)} kcal'),
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
