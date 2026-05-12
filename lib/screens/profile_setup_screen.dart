import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final Map<String, dynamic>? profile;
  const ProfileSetupScreen({super.key, this.profile});
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  late Map<String, dynamic> _data;

  @override
  void initState() {
    super.initState();
    _data = Map.from(widget.profile ?? {});
  }

  @override
  void didUpdateWidget(ProfileSetupScreen old) {
    super.didUpdateWidget(old);
    if (old.profile != widget.profile) {
      setState(() => _data = Map.from(widget.profile ?? {}));
    }
  }

  String get _activityLabel {
    switch (_data['activity_level']) {
      case 'sedentary':
        return 'Ít vận động';
      case 'light':
        return 'Nhẹ';
      case 'moderate':
        return 'Vừa phải';
      case 'active':
        return 'Nhiều';
      case 'very_active':
        return 'Rất nhiều';
      default:
        return '--';
    }
  }

  String get _goalLabel {
    switch (_data['goal_type']) {
      case 'lose_weight':
        return 'Giảm cân';
      case 'gain_weight':
        return 'Tăng cân';
      case 'maintain':
        return 'Giữ cân';
      case 'build_muscle':
        return 'Tăng cơ';
      default:
        return '--';
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  void _editProfile() async {
    final updated = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditProfileSheet(data: _data),
    );
    if (updated != null) {
      await ApiService.updateProfile(updated);
      setState(() => _data = {..._data, ...updated});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật hồ sơ'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _data['name'] ?? 'Người dùng';
    final email = _data['email'] ?? '';
    final age = _data['age'] ?? '--';
    final height = _data['height'] ?? '--';
    final weight = _data['weight'] ?? '--';
    final cal = _data['daily_calorie_goal'] ?? '--';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // ── Avatar ────────────────────────────────────
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 36,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _editProfile,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            Text(email, style: const TextStyle(color: AppColors.textGrey)),
            const SizedBox(height: 24),

            // ── Thông tin cơ thể ──────────────────────────
            _infoCard([
              _infoRow(Icons.cake_outlined, 'Tuổi', '$age tuổi'),
              _infoRow(Icons.height, 'Chiều cao', '$height cm'),
              _infoRow(Icons.monitor_weight_outlined, 'Cân nặng', '$weight kg'),
              _infoRow(Icons.directions_run, 'Vận động', _activityLabel),
            ]),
            const SizedBox(height: 12),

            // ── Mục tiêu ──────────────────────────────────
            _infoCard([
              _infoRow(Icons.flag_outlined, 'Mục tiêu', _goalLabel),
              _infoRow(
                Icons.local_fire_department_outlined,
                'Calo/ngày',
                '$cal kcal',
              ),
              if (_data['daily_protein_goal'] != null)
                _infoRow(
                  Icons.fitness_center,
                  'Protein/ngày',
                  '${_data['daily_protein_goal']}g',
                ),
            ]),
            const SizedBox(height: 12),

            // ── Menu ──────────────────────────────────────
            _menuItem(Icons.flag_outlined, 'Thay đổi mục tiêu', () {}),
            const SizedBox(height: 8),
            _menuItem(Icons.notifications_outlined, 'Cài đặt thông báo', () {}),
            const SizedBox(height: 8),
            _menuItem(Icons.logout, 'Đăng xuất', _logout, color: AppColors.fat),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(children: children),
  );

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppColors.textGrey)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ],
    ),
  );

  Widget _menuItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color ?? AppColors.textGrey, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: color ?? AppColors.textDark, fontSize: 15),
          ),
          const Spacer(),
          Icon(
            Icons.chevron_right,
            color: color ?? AppColors.textGrey,
            size: 20,
          ),
        ],
      ),
    ),
  );
}

// ── Sheet chỉnh sửa hồ sơ ─────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  final Map<String, dynamic> data;
  const _EditProfileSheet({required this.data});
  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _weightCtrl;
  late String _activity;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.data['name'] ?? '');
    _ageCtrl = TextEditingController(text: '${widget.data['age'] ?? ''}');
    _heightCtrl = TextEditingController(text: '${widget.data['height'] ?? ''}');
    _weightCtrl = TextEditingController(text: '${widget.data['weight'] ?? ''}');
    _activity = widget.data['activity_level'] ?? 'moderate';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chỉnh sửa hồ sơ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _field(_nameCtrl, 'Họ và tên'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field(_ageCtrl, 'Tuổi', isNum: true)),
                const SizedBox(width: 10),
                Expanded(child: _field(_heightCtrl, 'Cao (cm)', isNum: true)),
                const SizedBox(width: 10),
                Expanded(child: _field(_weightCtrl, 'Nặng (kg)', isNum: true)),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _activity,
              decoration: InputDecoration(
                labelText: 'Mức vận động',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'sedentary',
                  child: Text('Ít vận động'),
                ),
                DropdownMenuItem(value: 'light', child: Text('Nhẹ')),
                DropdownMenuItem(value: 'moderate', child: Text('Vừa')),
                DropdownMenuItem(value: 'active', child: Text('Nhiều')),
                DropdownMenuItem(
                  value: 'very_active',
                  child: Text('Rất nhiều'),
                ),
              ],
              onChanged: (v) => setState(() => _activity = v!),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pop(context, {
                  'name': _nameCtrl.text,
                  'age': int.tryParse(_ageCtrl.text),
                  'height': double.tryParse(_heightCtrl.text),
                  'weight': double.tryParse(_weightCtrl.text),
                  'activity_level': _activity,
                }),
                child: const Text(
                  'Lưu thay đổi',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {bool isNum = false}) =>
      TextField(
        controller: c,
        keyboardType: isNum
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: AppColors.background,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 12,
          ),
        ),
      );
}
