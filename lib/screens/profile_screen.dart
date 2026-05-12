import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic>? profile;

  const ProfileScreen({super.key, this.profile});

  Map<String, dynamic> get _p {
    if (profile == null) return {};

    if (profile!['data'] is Map<String, dynamic>) {
      return profile!['data'];
    }

    if (profile!['profile'] is Map<String, dynamic>) {
      return profile!['profile'];
    }

    if (profile!['user'] is Map<String, dynamic>) {
      return profile!['user'];
    }

    return profile!;
  }

  String _getValue(List<String> keys, {String fallback = '--'}) {
    for (final key in keys) {
      final value = _p[key];

      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }

  String _getActivityLabel() {
    final value = _getValue(['activity_level'], fallback: '');

    switch (value) {
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

  String _getGoalLabel() {
    final value = _getValue(['goal_type'], fallback: '');

    switch (value) {
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

  Future<void> _handleLogout(BuildContext context) async {
    await ApiService.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _getValue(['name', 'full_name'], fallback: 'Người dùng');
    final email = _getValue(['email'], fallback: '');
    final age = _getValue(['age']);
    final height = _getValue(['height']);
    final weight = _getValue(['weight']);
    final dailyCalorieGoal = _getValue(['daily_calorie_goal', 'calorie_goal']);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),

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

            const SizedBox(height: 12),

            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
            ),

            const SizedBox(height: 24),

            _infoCard([
              _infoRow(Icons.cake_outlined, 'Tuổi', '$age tuổi'),
              _infoRow(Icons.height, 'Chiều cao', '$height cm'),
              _infoRow(Icons.monitor_weight_outlined, 'Cân nặng', '$weight kg'),
              _infoRow(Icons.directions_run, 'Vận động', _getActivityLabel()),
            ]),

            const SizedBox(height: 12),

            _infoCard([
              _infoRow(Icons.flag_outlined, 'Mục tiêu', _getGoalLabel()),
              _infoRow(
                Icons.local_fire_department_outlined,
                'Calo/ngày',
                '$dailyCalorieGoal kcal',
              ),
            ]),

            const SizedBox(height: 12),

            _menuItem(Icons.flag_outlined, 'Thay đổi mục tiêu', () {}),

            const SizedBox(height: 8),

            _menuItem(Icons.notifications_outlined, 'Cài đặt thông báo', () {}),

            const SizedBox(height: 8),

            _menuItem(Icons.help_outline, 'Trợ giúp', () {}),

            const SizedBox(height: 8),

            _menuItem(
              Icons.logout,
              'Đăng xuất',
              () => _handleLogout(context),
              color: AppColors.fat,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),

          const SizedBox(width: 12),

          Expanded(
            flex: 4,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            flex: 5,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? AppColors.textGrey, size: 20),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color ?? AppColors.textDark,
                  fontSize: 15,
                ),
              ),
            ),

            const SizedBox(width: 8),

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
}
