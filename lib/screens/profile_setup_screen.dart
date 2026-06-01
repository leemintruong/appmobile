import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/app_events.dart';
import '../theme/app_colors.dart';
import '../widgets/sk_ui.dart';
import 'home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _ageCtrl = TextEditingController(text: '22');
  final _heightCtrl = TextEditingController(text: '169');
  final _weightCtrl = TextEditingController(text: '59');
  final _targetCtrl = TextEditingController(text: '62');

  String _gender = 'male';
  String _activity = 'moderate';
  String _goal = 'gain_weight';
  bool _saving = false;

  @override
  void dispose() {
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  num get _weight => NumFmt.read(_weightCtrl.text, fallback: 59);
  num get _height => NumFmt.read(_heightCtrl.text, fallback: 169);
  num get _age => NumFmt.read(_ageCtrl.text, fallback: 22);

  num get _bmr {
    if (_gender == 'male') return 10 * _weight + 6.25 * _height - 5 * _age + 5;
    return 10 * _weight + 6.25 * _height - 5 * _age - 161;
  }

  num get _tdee {
    final factors = {'sedentary': 1.2, 'light': 1.375, 'moderate': 1.55, 'active': 1.725, 'very_active': 1.9};
    return _bmr * (factors[_activity] ?? 1.55);
  }

  num get _calorieGoal {
    switch (_goal) {
      case 'lose_weight': return (_tdee - 500).clamp(1200, 5000);
      case 'gain_weight': return _tdee + 300;
      case 'build_muscle': return _tdee + 200;
      default: return _tdee;
    }
  }

  Future<void> _save({bool finish = false}) async {
    setState(() => _saving = true);
    try {
      final profile = await ApiService.updateProfile({
        'gender': _gender,
        'age': int.tryParse(_ageCtrl.text) ?? 22,
        'height_cm': double.tryParse(_heightCtrl.text) ?? 169,
        'current_weight_kg': double.tryParse(_weightCtrl.text) ?? 59,
        'activity_level': _activity,
      });
      final goal = await ApiService.setGoal(_goal, targetWeight: double.tryParse(_targetCtrl.text));
      if (!mounted) return;
      if (profile['success'] == false || goal['success'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(profile['message'] ?? goal['message'] ?? 'Không lưu được hồ sơ')));
        return;
      }
      AppEvents.notifyDataChanged();
      if (finish) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu hồ sơ')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi lưu hồ sơ: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          children: [
            Row(children: [
              IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_back_rounded)),
              const Expanded(child: Text('Thiết lập hồ sơ', style: TextStyle(color: AppColors.textDark, fontSize: 26, fontWeight: FontWeight.w900))),
            ]),
            const SizedBox(height: 10),
            SkFadeSlide(child: _formCard()),
            const SizedBox(height: 16),
            SkFadeSlide(delayMs: 90, child: _goalSummary()),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: SkPrimaryButton(label: 'Lưu', onPressed: () => _save(), loading: _saving)),
              const SizedBox(width: 12),
              Expanded(child: SkOutlineButton(label: 'Hoàn tất', icon: Icons.done_rounded, onPressed: _saving ? null : () => _save(finish: true))),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _formCard() {
    return SkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Thông tin cơ bản', style: TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 16),
      _chips('Giới tính', {'male': 'Nam', 'female': 'Nữ', 'other': 'Khác'}, _gender, (v) => setState(() => _gender = v)),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: SkTextField(controller: _ageCtrl, label: 'Tuổi', hint: '22', keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
        const SizedBox(width: 12),
        Expanded(child: SkTextField(controller: _heightCtrl, label: 'Chiều cao', hint: 'cm', keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
      ]),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: SkTextField(controller: _weightCtrl, label: 'Cân nặng', hint: 'kg', keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
        const SizedBox(width: 12),
        Expanded(child: SkTextField(controller: _targetCtrl, label: 'Mục tiêu', hint: 'kg', keyboardType: TextInputType.number)),
      ]),
      const SizedBox(height: 16),
      _chips('Mức hoạt động', {'sedentary': 'Ít', 'moderate': 'Vừa', 'active': 'Nặng'}, _activity, (v) => setState(() => _activity = v)),
      const SizedBox(height: 16),
      _chips('Mục tiêu', {'maintain': 'Giữ cân', 'gain_weight': 'Tăng cân', 'lose_weight': 'Giảm cân', 'build_muscle': 'Tăng cơ'}, _goal, (v) => setState(() => _goal = v)),
    ]));
  }

  Widget _chips(String title, Map<String, String> values, String selected, ValueChanged<String> onTap) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: values.entries.map((e) => SkChip(label: e.value, selected: selected == e.key, onTap: () => onTap(e.key))).toList()),
    ]);
  }

  Widget _goalSummary() {
    return SkCard(
      color: AppColors.primary,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Mục tiêu calo hằng ngày', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('${_calorieGoal.toStringAsFixed(0)} kcal / ngày', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(_goalHint(), style: const TextStyle(color: Colors.white70, height: 1.35)),
      ]),
    );
  }

  String _goalHint() {
    switch (_goal) {
      case 'lose_weight': return 'Ứng dụng đề xuất giảm nhẹ calo và ưu tiên protein để giảm cân an toàn.';
      case 'gain_weight': return 'Ứng dụng đề xuất tăng nhẹ calo để hỗ trợ tăng cân lành mạnh.';
      case 'build_muscle': return 'Tăng cơ cần đủ calo và protein, kết hợp vận động đều.';
      default: return 'Mức calo này giúp bạn duy trì cân nặng ổn định.';
    }
  }
}
