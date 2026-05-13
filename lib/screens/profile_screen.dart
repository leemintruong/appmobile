import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'profile_setup_screen.dart';
import 'weight_screen.dart';

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

  String _goalLabel() {
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
        return 'Giữ cân';
    }
  }

  String _activityLabel() {
    final value = _getValue(['activity_level'], fallback: '');

    switch (value) {
      case 'sedentary':
        return 'Ít vận động';
      case 'light':
        return 'Ít hoạt động';
      case 'moderate':
        return 'Hoạt động vừa';
      case 'active':
        return 'Rất năng động';
      case 'very_active':
        return 'Cường độ cao';
      default:
        return 'Chưa cập nhật';
    }
  }

  Future<void> _logout(BuildContext context) async {
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
    final email = _getValue(['email'], fallback: 'user@example.com');
    final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    final age = _getValue(['age']);
    final height = _getValue(['height']);
    final weight = _getValue(['weight']);
    final dailyCalorieGoal = _getValue([
      'daily_calorie_goal',
    ], fallback: '2200');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
          children: [
            _topHeader(),
            const SizedBox(height: 16),
            _profileCard(name: name, email: email, firstLetter: firstLetter),
            const SizedBox(height: 16),
            _statsCard(
              age: age,
              height: height,
              weight: weight,
              dailyCalorieGoal: dailyCalorieGoal,
            ),
            const SizedBox(height: 16),
            _settingsCard(context),
          ],
        ),
      ),
    );
  }

  Widget _topHeader() {
    return Row(
      children: [
        const Text(
          'Hồ sơ người dùng',
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
            Icons.settings,
            color: AppColors.textDark,
            size: 21,
          ),
        ),
      ],
    );
  }

  Widget _profileCard({
    required String name,
    required String email,
    required String firstLetter,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primarySoft,
            child: Text(
              firstLetter,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mục tiêu: ${_goalLabel()}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsCard({
    required String age,
    required String height,
    required String weight,
    required String dailyCalorieGoal,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin sức khỏe',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _smallStat('Tuổi', age),
              const SizedBox(width: 10),
              _smallStat('Chiều cao', '$height cm'),
              const SizedBox(width: 10),
              _smallStat('Cân nặng', '$weight kg'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _infoLine(
                  title: 'Mức hoạt động',
                  value: _activityLabel(),
                  icon: Icons.directions_run,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoLine(
                  title: 'Calo mục tiêu',
                  value: '$dailyCalorieGoal kcal',
                  icon: Icons.local_fire_department,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallStat(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoLine({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cài đặt tài khoản',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _menuRow(
            icon: Icons.person_outline,
            title: 'Chỉnh sửa hồ sơ',
            subtitle: 'Tuổi, chiều cao, cân nặng',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileSetupScreen(profile: _p),
                ),
              );
            },
          ),
          _menuRow(
            icon: Icons.monitor_weight_outlined,
            title: 'Theo dõi cân nặng',
            subtitle: 'Lịch sử cân nặng và mục tiêu',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WeightScreen()),
              );
            },
          ),
          _menuRow(
            icon: Icons.notifications_none,
            title: 'Thông báo',
            subtitle: 'Nhắc ghi bữa ăn và cân nặng',
            onTap: () {},
          ),
          _menuRow(
            icon: Icons.straighten,
            title: 'Đơn vị đo',
            subtitle: 'kg / cm',
            onTap: () {},
          ),
          _menuRow(
            icon: Icons.logout,
            title: 'Đăng xuất',
            subtitle: 'Thoát khỏi tài khoản hiện tại',
            onTap: () => _logout(context),
            danger: true,
          ),
        ],
      ),
    );
  }

  Widget _menuRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final color = danger ? AppColors.danger : AppColors.textDark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F2F3))),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: danger ? const Color(0xFFFFEFEF) : AppColors.background,
                borderRadius: BorderRadius.circular(21),
              ),
              child: Icon(
                icon,
                color: danger ? AppColors.danger : AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
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
            const Icon(Icons.chevron_right, color: AppColors.textLight),
          ],
        ),
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
