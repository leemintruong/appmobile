import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'profile_setup_screen.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic>? profile;

  const ProfileScreen({super.key, this.profile});

  Map<String, dynamic> get _p {
    if (profile == null) return {};
    if (profile!['data'] is Map<String, dynamic>) return profile!['data'];
    if (profile!['profile'] is Map<String, dynamic>) return profile!['profile'];
    if (profile!['user'] is Map<String, dynamic>) return profile!['user'];
    return profile!;
  }

  String _getValue(List<String> keys, {String fallback = '--'}) {
    for (final key in keys) {
      final value = _p[key];
      if (value != null && value.toString().isNotEmpty) return value.toString();
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
        return 'Giảm cân';
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
    final name = _getValue(['name', 'full_name'], fallback: 'Nguyễn Văn A');
    final first = name.isNotEmpty ? name[0].toUpperCase() : 'A';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
          children: [
            const Text(
              'Cá nhân',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 44),
            _profileHeader(first, name),
            const SizedBox(height: 44),
            _menuCard(
              title: 'Hồ sơ cá nhân',
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
            const SizedBox(height: 14),
            _menuCard(
              title: 'Mục tiêu dinh dưỡng',
              subtitle: 'Calo, protein, carb, fat',
              onTap: () {},
            ),
            const SizedBox(height: 14),
            _menuCard(
              title: 'Cài đặt thông báo',
              subtitle: 'Nhắc bữa ăn, cân nặng',
              onTap: () {},
            ),
            const SizedBox(height: 14),
            _menuCard(title: 'Đơn vị đo', subtitle: 'kg/cm', onTap: () {}),
            const SizedBox(height: 14),
            _menuCard(
              title: 'Đăng xuất',
              subtitle: 'Thoát tài khoản',
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileHeader(String first, String name) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.62),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 31,
            backgroundColor: AppColors.softGreen,
            child: Text(
              first,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 28,
              ),
            ),
          ),
          const SizedBox(width: 18),
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
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mục tiêu: ${_goalLabel()}',
                  style: const TextStyle(
                    color: AppColors.textGrey,
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

  Widget _menuCard({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.62),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textLight,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
