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
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  String _gender = 'male';
  String _activityLevel = 'moderate';
  String _goalType = 'lose_weight';

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final p = widget.profile ?? {};

    _ageCtrl.text = (p['age'] ?? '').toString();
    _heightCtrl.text = (p['height'] ?? '').toString();
    _weightCtrl.text = (p['weight'] ?? '').toString();

    if (p['gender'] != null) _gender = p['gender'].toString();
    if (p['activity_level'] != null) {
      _activityLevel = p['activity_level'].toString();
    }
    if (p['goal_type'] != null) _goalType = p['goal_type'].toString();
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
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

      final goalResult = await ApiService.setGoal(_goalType);

      if (!mounted) return;

      if (goalResult['success'] == false) {
        _showMessage(goalResult['message'] ?? 'Không lưu được mục tiêu');
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage('Không kết nối được backend: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          children: [
            const Text(
              'Thiết lập hồ sơ',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Thông tin này giúp hệ thống tính mục tiêu calo.',
              style: TextStyle(fontSize: 16, color: AppColors.textGrey),
            ),
            const SizedBox(height: 28),

            Row(
              children: [
                Expanded(
                  child: _smallField(
                    label: 'Tuổi',
                    controller: _ageCtrl,
                    hint: '22',
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(child: _genderPicker()),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: _smallField(
                    label: 'Chiều cao',
                    controller: _heightCtrl,
                    hint: '170 cm',
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: _smallField(
                    label: 'Cân nặng',
                    controller: _weightCtrl,
                    hint: '65 kg',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 42),

            const Text(
              'Mức độ vận động',
              style: TextStyle(
                color: AppColors.textGrey,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _pill(
                    label: 'Ít',
                    selected: _activityLevel == 'light',
                    onTap: () => setState(() => _activityLevel = 'light'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _pill(
                    label: 'Trung bình',
                    selected: _activityLevel == 'moderate',
                    onTap: () => setState(() => _activityLevel = 'moderate'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _pill(
                    label: 'Cao',
                    selected: _activityLevel == 'active',
                    onTap: () => setState(() => _activityLevel = 'active'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 42),

            const Text(
              'Mục tiêu',
              style: TextStyle(
                color: AppColors.textGrey,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),

            _goalCard(label: 'Giảm cân', value: 'lose_weight'),
            const SizedBox(height: 14),
            _goalCard(label: 'Giữ cân', value: 'maintain'),
            const SizedBox(height: 14),
            _goalCard(label: 'Tăng cân / tăng cơ', value: 'build_muscle'),

            const SizedBox(height: 54),

            SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 23,
                        height: 23,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Lưu hồ sơ',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textGrey,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textLight),
            filled: true,
            fillColor: Colors.white.withOpacity(0.65),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _genderPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Giới tính',
          style: TextStyle(
            color: AppColors.textGrey,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _gender,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.65),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'male', child: Text('Nam')),
            DropdownMenuItem(value: 'female', child: Text('Nữ')),
            DropdownMenuItem(value: 'other', child: Text('Khác')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _gender = value);
          },
        ),
      ],
    );
  }

  Widget _pill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 46,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.softGreen
              : Colors.white.withOpacity(0.45),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.primaryDark : AppColors.textGrey,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _goalCard({required String label, required String value}) {
    final selected = _goalType == value;

    return GestureDetector(
      onTap: () => setState(() => _goalType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.65),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.inputBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check, color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}
