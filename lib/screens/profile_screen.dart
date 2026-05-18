import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'profile_setup_screen.dart';
import 'weight_screen.dart';
import 'water_screen.dart';
import 'activity_screen.dart';
import 'ai_scan_screen.dart';

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

  String _getValue(List<String> keys, {String fallback = 'Chưa cập nhật'}) {
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
      case 'build_muscle':
        return 'Tăng cơ';
      case 'maintain':
        return 'Giữ cân';
      default:
        return 'Chưa thiết lập';
    }
  }

  String _activityLabel() {
    final value = _getValue(['activity_level'], fallback: '');

    switch (value) {
      case 'sedentary':
        return 'Ít vận động';
      case 'light':
        return 'Nhẹ';
      case 'moderate':
        return 'Vừa phải';
      case 'active':
        return 'Năng động';
      case 'very_active':
        return 'Rất năng động';
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
    final height = _getValue(['height_cm', 'height']);
    final weight = _getValue(['current_weight_kg', 'weight']);
    final dailyCalorieGoal = _getValue(['daily_calorie_goal'], fallback: '2200');
    final dailyWaterGoal = _getValue(['daily_water_goal_ml'], fallback: '2000');

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
              dailyWaterGoal: dailyWaterGoal,
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
          child: const Icon(Icons.settings, color: AppColors.textDark, size: 21),
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
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
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
    required String dailyWaterGoal,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin cá nhân',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _statItem('Tuổi', age)),
              Expanded(child: _statItem('Chiều cao', '$height cm')),
              Expanded(child: _statItem('Cân nặng', '$weight kg')),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _statItem('Calo/ngày', '$dailyCalorieGoal kcal')),
              Expanded(child: _statItem('Nước/ngày', '$dailyWaterGoal ml')),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Mức vận động: ${_activityLabel()}',
            style: const TextStyle(color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _menuRow(
            icon: Icons.person_outline,
            title: 'Cập nhật hồ sơ',
            subtitle: 'Tuổi, chiều cao, cân nặng, mục tiêu',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileSetupScreen(profile: _p)),
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
            icon: Icons.water_drop_outlined,
            title: 'Theo dõi nước uống',
            subtitle: 'Ghi lượng nước uống mỗi ngày',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WaterScreen()),
              );
            },
          ),
          _menuRow(
            icon: Icons.directions_walk,
            title: 'Theo dõi vận động',
            subtitle: 'Hoạt động thể chất và calo tiêu hao',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ActivityScreen()),
              );
            },
          ),
          _menuRow(
            icon: Icons.auto_awesome,
            title: 'AI quét món ăn',
            subtitle: 'Demo nhận diện món ăn bằng ảnh',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiScanScreen()),
              );
            },
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
                    style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
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
