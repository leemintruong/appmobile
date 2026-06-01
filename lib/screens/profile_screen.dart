import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/sk_ui.dart';
import 'activity_screen.dart';
import 'login_screen.dart';
import 'profile_setup_screen.dart';
import 'water_screen.dart';
import 'weight_screen.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic> profile;
  const ProfileScreen({super.key, required this.profile});

  num _n(dynamic v) => NumFmt.read(v);

  @override
  Widget build(BuildContext context) {
    final name = profile['name'] ?? 'Người dùng';
    final email = profile['email'] ?? '';
    final weight = _n(profile['current_weight_kg']);
    final height = _n(profile['height_cm']);
    final age = _n(profile['age']);
    final goal = _n(profile['daily_calorie_goal']);
    final target = _n(profile['target_weight_kg']);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
        children: [
          const Text('Hồ sơ', style: TextStyle(color: AppColors.textDark, fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          SkFadeSlide(child: _userCard(context, '$name', '$email', weight, height, age)),
          const SizedBox(height: 16),
          SkFadeSlide(delayMs: 80, child: _goalCard(goal, target)),
          const SizedBox(height: 16),
          SkFadeSlide(delayMs: 110, child: _menu(context)),
          const SizedBox(height: 16),
          SkFadeSlide(delayMs: 140, child: _logout(context)),
        ],
      ),
    );
  }

  Widget _userCard(BuildContext context, String name, String email, num weight, num height, num age) {
    return SkCard(
      child: Column(children: [
        Row(children: [
          Container(width: 72, height: 72, decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle), child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 38)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(email, style: const TextStyle(color: AppColors.textGrey)),
          ])),
          IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSetupScreen())), icon: const Icon(Icons.edit_rounded, color: AppColors.primary)),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: _mini('Cân nặng', weight > 0 ? '${weight.toStringAsFixed(1)} kg' : '--')),
          Expanded(child: _mini('Chiều cao', height > 0 ? '${height.toStringAsFixed(0)} cm' : '--')),
          Expanded(child: _mini('Tuổi', age > 0 ? '${age.toStringAsFixed(0)}' : '--')),
        ]),
      ]),
    );
  }

  Widget _goalCard(num goal, num target) {
    return SkCard(
      color: AppColors.primary,
      child: Row(children: [
        const Icon(Icons.flag_rounded, color: Colors.white, size: 38),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Mục tiêu hôm nay', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
          Text(goal > 0 ? '${goal.toStringAsFixed(0)} kcal' : 'Chưa thiết lập', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
          Text(target > 0 ? 'Cân nặng mục tiêu: ${target.toStringAsFixed(1)} kg' : 'Cập nhật hồ sơ để tính chính xác hơn', style: const TextStyle(color: Colors.white70)),
        ])),
      ]),
    );
  }

  Widget _menu(BuildContext context) {
    return SkCard(
      child: Column(children: [
        _tile(context, Icons.monitor_weight_rounded, 'Theo dõi cân nặng', const WeightScreen()),
        _tile(context, Icons.water_drop_rounded, 'Theo dõi nước uống', const WaterScreen()),
        _tile(context, Icons.directions_walk_rounded, 'Theo dõi vận động', const ActivityScreen()),
        _tile(context, Icons.settings_rounded, 'Thiết lập hồ sơ', const ProfileSetupScreen()),
      ]),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, Widget page) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: AppColors.primary)),
      title: Text(title, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    );
  }

  Widget _logout(BuildContext context) {
    return SkCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
        title: const Text('Đăng xuất', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w900)),
        onTap: () async {
          await ApiService.logout();
          if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
        },
      ),
    );
  }

  Widget _mini(String label, String value) {
    return Column(children: [
      Text(value, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w900)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
    ]);
  }
}
