import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final Map<String, dynamic>? profile;

  const ProfileSetupScreen({super.key, this.profile});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _ageCtrl = TextEditingController(text: '100');
  final _heightCtrl = TextEditingController(text: '170');
  final _weightCtrl = TextEditingController(text: '68');

  String _gender = 'male';
  String _activityLevel = 'active';
  String _goalType = 'gain_weight';

  double _calorieTarget = 2400;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final p = widget.profile ?? {};

    if (p['age'] != null) _ageCtrl.text = p['age'].toString();
    if (p['height'] != null) _heightCtrl.text = p['height'].toString();
    if (p['weight'] != null) _weightCtrl.text = p['weight'].toString();
    if (p['gender'] != null) _gender = p['gender'].toString();
    if (p['activity_level'] != null) {
      _activityLevel = p['activity_level'].toString();
    }
    if (p['goal_type'] != null) _goalType = p['goal_type'].toString();
    if (p['daily_calorie_goal'] != null) {
      _calorieTarget =
          double.tryParse(p['daily_calorie_goal'].toString()) ?? 2400;
    }
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile({bool finish = false}) async {
    final age = int.tryParse(_ageCtrl.text.trim());
    final height = double.tryParse(_heightCtrl.text.trim());
    final weight = double.tryParse(_weightCtrl.text.trim());

    if (age == null || height == null || weight == null) {
      _showMessage('Vui lòng nhập đúng tuổi, chiều cao và cân nặng');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final profileResult = await ApiService.updateProfile({
        'gender': _gender,
        'age': age,
        'height': height,
        'weight': weight,
        'activity_level': _activityLevel,
      });

      if (!mounted) return;

      if (profileResult['success'] == false) {
        _showMessage(profileResult['message'] ?? 'Không lưu được hồ sơ');
        return;
      }

      final goalResult = await ApiService.setGoal(
        _goalType,
        targetWeight: _goalType == 'lose_weight' ? 60 : null,
      );

      if (!mounted) return;

      if (goalResult['success'] == false) {
        _showMessage(goalResult['message'] ?? 'Không lưu được mục tiêu');
        return;
      }

      if (finish) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        _showMessage('Đã lưu hồ sơ');
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('Không kết nối được máy chủ: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  double _estimateBmr() {
    final age = int.tryParse(_ageCtrl.text) ?? 25;
    final height = double.tryParse(_heightCtrl.text) ?? 170;
    final weight = double.tryParse(_weightCtrl.text) ?? 68;

    if (_gender == 'male') {
      return 10 * weight + 6.25 * height - 5 * age + 5;
    }

    return 10 * weight + 6.25 * height - 5 * age - 161;
  }

  double _estimateTdee() {
    final bmr = _estimateBmr();

    final factor = switch (_activityLevel) {
      'sedentary' => 1.2,
      'light' => 1.375,
      'moderate' => 1.55,
      'active' => 1.725,
      'very_active' => 1.9,
      _ => 1.55,
    };

    return bmr * factor;
  }

  @override
  Widget build(BuildContext context) {
    final bmr = _estimateBmr();
    final tdee = _estimateTdee();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _topHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _setupCard(bmr, tdee),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            _bottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _topHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.close, size: 20),
            ),
          ),
          const Expanded(
            child: Text(
              'Thiết lập hồ sơ',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 34),
        ],
      ),
    );
  }

  Widget _setupCard(double bmr, double tdee) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _welcomeBlock(),
          const SizedBox(height: 18),

          _sectionLabel('Giới tính'),
          const SizedBox(height: 8),
          Row(
            children: [
              _radioPill('male', 'Nam'),
              const SizedBox(width: 8),
              _radioPill('female', 'Nữ'),
              const SizedBox(width: 8),
              _radioPill('other', 'Khác'),
            ],
          ),

          const SizedBox(height: 14),

          _sectionLabel('Tuổi'),
          const SizedBox(height: 6),
          _numberInput(_ageCtrl),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _labeledNumberInput(
                  label: 'Chiều cao (cm)',
                  controller: _heightCtrl,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _labeledNumberInput(
                  label: 'Cân nặng (kg)',
                  controller: _weightCtrl,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _sectionLabel('Mức hoạt động'),
          const SizedBox(height: 8),
          Row(
            children: [
              _activityCard('light', 'Ít hoạt động'),
              const SizedBox(width: 8),
              _activityCard('moderate', 'Hoạt động\nvừa'),
              const SizedBox(width: 8),
              _activityCard('active', 'Rất năng\nđộng'),
            ],
          ),

          const SizedBox(height: 16),

          _sectionLabel('Mục tiêu'),
          const SizedBox(height: 8),
          Row(
            children: [
              _goalPill('maintain', 'Giữ cân'),
              const SizedBox(width: 8),
              _goalPill('gain_weight', 'Tăng cân'),
              const SizedBox(width: 8),
              _goalPill('lose_weight', 'Giảm cân'),
            ],
          ),

          const SizedBox(height: 18),

          _estimateCard(bmr, tdee),

          const SizedBox(height: 14),

          _calorieSlider(),

          const SizedBox(height: 14),

          _suggestionCard(),

          const SizedBox(height: 16),

          const Divider(color: AppColors.border),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _isSaving
                        ? null
                        : () => _saveProfile(finish: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.2,
                            ),
                          )
                        : const Text(
                            'Lưu',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: _isSaving
                        ? null
                        : () => _saveProfile(finish: true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textDark,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: const Text('Hoàn tất'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _welcomeBlock() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(29),
          ),
          child: const Center(
            child: Text('🥗', style: TextStyle(fontSize: 31)),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chào mừng! Hoàn thiện hồ sơ để nhận kế hoạch dinh dưỡng cá nhân hóa.',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 15,
                  height: 1.32,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Thao tác nhanh: chọn các thông tin cơ bản bên dưới.',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 12.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textDark,
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _radioPill(String value, String label) {
    final selected = _gender == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: Container(
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 17,
                color: selected ? AppColors.textDark : AppColors.textGrey,
              ),
              const SizedBox(width: 7),
              Text(label, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numberInput(TextEditingController controller) {
    return SizedBox(
      height: 46,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 16, color: AppColors.textDark),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _labeledNumberInput({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(label),
        const SizedBox(height: 6),
        _numberInput(controller),
      ],
    );
  }

  Widget _activityCard(String value, String label) {
    final selected = _activityLevel == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activityLevel = value),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.textDark : AppColors.textGrey,
                size: 18,
              ),
              const Spacer(),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, height: 1.1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _goalPill(String value, String label) {
    final selected = _goalType == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _goalType = value),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primaryDark : AppColors.textDark,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _estimateCard(double bmr, double tdee) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: AppColors.textDark),
                children: [
                  const TextSpan(
                    text: 'Ước tính nhu cầu\n',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 12.5),
                  ),
                  TextSpan(
                    text: 'BMR ${bmr.toStringAsFixed(0)} kcal •\n',
                    style: const TextStyle(fontSize: 20),
                  ),
                  TextSpan(
                    text: 'TDEE ${tdee.toStringAsFixed(0)} kcal',
                    style: const TextStyle(fontSize: 20),
                  ),
                ],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Mục tiêu\nhôm nay',
                textAlign: TextAlign.right,
                style: TextStyle(color: AppColors.textGrey, fontSize: 11.5),
              ),
              const SizedBox(height: 6),
              Text(
                '${_calorieTarget.toStringAsFixed(0)} /\n${tdee.toStringAsFixed(0)} kcal',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _calorieSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Điều chỉnh mục tiêu calo',
              style: TextStyle(fontSize: 13),
            ),
            const Spacer(),
            Text(
              '${_calorieTarget.toStringAsFixed(0)} kcal',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        SizedBox(
          height: 32,
          child: Slider(
            value: _calorieTarget,
            min: 1200,
            max: 3500,
            divisions: 23,
            activeColor: Colors.black,
            inactiveColor: AppColors.border,
            onChanged: (value) => setState(() => _calorieTarget = value),
          ),
        ),
        const Text(
          'Kéo để tăng/giảm mục tiêu calo hằng ngày',
          style: TextStyle(color: AppColors.textGrey, fontSize: 11.5),
        ),
      ],
    );
  }

  Widget _suggestionCard() {
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(27),
          ),
          child: const Center(
            child: Text('🌄', style: TextStyle(fontSize: 29)),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Gợi ý: Để giảm 0.5kg/tuần, giảm ~500 kcal/ngày. Áp dụng tăng hoạt động thể chất để giữ cơ bắp.',
            style: TextStyle(
              color: AppColors.textDark,
              height: 1.28,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomNav() {
    return Container(
      height: 56,
      color: Colors.white,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BottomItem(icon: Icons.home, label: 'Trang chủ'),
          _BottomItem(icon: Icons.person, label: 'Hồ sơ'),
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BottomItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.textDark, size: 20),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.textGrey, fontSize: 11),
        ),
      ],
    );
  }
}
