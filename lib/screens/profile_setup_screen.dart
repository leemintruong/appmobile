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
  final _ageCtrl = TextEditingController(text: '22');
  final _heightCtrl = TextEditingController(text: '170');
  final _weightCtrl = TextEditingController(text: '65');

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
    if (p['height_cm'] != null) {
      _heightCtrl.text = p['height_cm'].toString();
    } else if (p['height'] != null) {
      _heightCtrl.text = p['height'].toString();
    }

    if (p['current_weight_kg'] != null) {
      _weightCtrl.text = p['current_weight_kg'].toString();
    } else if (p['weight'] != null) {
      _weightCtrl.text = p['weight'].toString();
    }
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
        'height_cm': height,
        'current_weight_kg': weight,
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

  double _suggestedCalorieTarget() {
    final tdee = _estimateTdee();

    final adjusted = switch (_goalType) {
      'lose_weight' => tdee - 500,
      'gain_weight' => tdee + 300,
      'build_muscle' => tdee + 200,
      _ => tdee,
    };

    return adjusted.clamp(1200, 3500).toDouble();
  }

  String _goalLabel() {
    return switch (_goalType) {
      'lose_weight' => 'Giảm cân',
      'gain_weight' => 'Tăng cân',
      'build_muscle' => 'Tăng cơ',
      _ => 'Giữ cân',
    };
  }

  String _goalDescription() {
    return switch (_goalType) {
      'lose_weight' =>
        'Ứng dụng đề xuất mức calo thấp hơn nhu cầu duy trì để hỗ trợ giảm cân an toàn.',
      'gain_weight' =>
        'Ứng dụng đề xuất tăng nhẹ calo mỗi ngày để hỗ trợ tăng cân lành mạnh.',
      'build_muscle' =>
        'Ứng dụng đề xuất tăng nhẹ calo và ưu tiên protein để hỗ trợ tăng cơ.',
      _ =>
        'Ứng dụng đề xuất mức calo gần với nhu cầu duy trì cân nặng hiện tại.',
    };
  }

  String _goalSuggestion() {
    return switch (_goalType) {
      'lose_weight' =>
        'Gợi ý: Để giảm cân an toàn, hãy giảm nhẹ lượng calo mỗi ngày, ưu tiên thực phẩm giàu protein và hạn chế đồ chiên/ngọt.',
      'gain_weight' =>
        'Gợi ý: Để tăng cân lành mạnh, hãy tăng nhẹ lượng calo mỗi ngày và bổ sung protein từ trứng, sữa, thịt nạc, cá hoặc đậu hũ.',
      'build_muscle' =>
        'Gợi ý: Để tăng cơ, hãy ăn đủ protein, ngủ đủ và kết hợp tập luyện đều đặn thay vì chỉ tăng calo.',
      _ =>
        'Gợi ý: Mục tiêu hiện tại giúp bạn duy trì cân nặng ổn định. Hãy ghi bữa ăn đều để app theo dõi chính xác hơn.',
    };
  }

  void _updateSuggestedTarget() {
    _calorieTarget = _suggestedCalorieTarget();
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
              _activityCard('light', 'Dân văn phòng'),
              const SizedBox(width: 8),
              _activityCard('moderate', 'Lao động nặng'),
              const SizedBox(width: 8),
              _activityCard('active', 'Vận động viên'),
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
          child: const Icon(
            Icons.restaurant_menu_rounded,
            color: AppColors.primary,
            size: 30,
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
        onTap: () => setState(() {
          _gender = value;
          _updateSuggestedTarget();
        }),
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
        onChanged: (_) => setState(() {
          _updateSuggestedTarget();
        }),
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
        onTap: () => setState(() {
          _activityLevel = value;
          _updateSuggestedTarget();
        }),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.primaryDark : AppColors.textGrey,
                size: 19,
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, height: 1.05),
                ),
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
        onTap: () => setState(() {
          _goalType = value;
          _updateSuggestedTarget();
        }),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(21),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mục tiêu calo hằng ngày',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_calorieTarget.toStringAsFixed(0)} kcal / ngày',
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Phù hợp với mục tiêu: ${_goalLabel()}',
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _goalDescription(),
            style: const TextStyle(
              color: AppColors.textGrey,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _showCalculationInfo(bmr, tdee),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: AppColors.primary,
            ),
            icon: const Icon(Icons.info_outline_rounded, size: 17),
            label: const Text(
              'Xem cách ứng dụng ước tính',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
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
              'Điều chỉnh nếu cần',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '${_calorieTarget.toStringAsFixed(0)} kcal',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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
            activeColor: AppColors.primary,
            inactiveColor: AppColors.border,
            onChanged: (value) => setState(() => _calorieTarget = value),
          ),
        ),
        const Text(
          'Bạn có thể kéo để tăng/giảm mục tiêu nếu thấy chưa phù hợp với thói quen ăn uống.',
          style: TextStyle(
            color: AppColors.textGrey,
            fontSize: 11.5,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _suggestionCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: AppColors.primary,
              size: 25,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _goalSuggestion(),
              style: const TextStyle(
                color: AppColors.textDark,
                height: 1.32,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCalculationInfo(double bmr, double tdee) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ứng dụng tính như thế nào?',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Ứng dụng ước tính nhu cầu năng lượng dựa trên tuổi, giới tính, chiều cao, cân nặng và mức độ vận động của bạn. Bạn không cần nhớ các chỉ số này, hệ thống chỉ dùng chúng để gợi ý mục tiêu calo ban đầu.',
                style: TextStyle(
                  color: AppColors.textGrey,
                  height: 1.4,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              _infoRow('Năng lượng cơ bản', '${bmr.toStringAsFixed(0)} kcal'),
              const SizedBox(height: 8),
              _infoRow(
                'Nhu cầu duy trì ước tính',
                '${tdee.toStringAsFixed(0)} kcal',
              ),
              const SizedBox(height: 8),
              _infoRow(
                'Mục tiêu hiện tại',
                '${_calorieTarget.toStringAsFixed(0)} kcal / ngày',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(23),
                    ),
                  ),
                  child: const Text('Đã hiểu'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w800,
            fontSize: 13,
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
