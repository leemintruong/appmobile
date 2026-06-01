import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/sk_ui.dart';

class ComingSoonScreen extends StatelessWidget {
  final String title;
  const ComingSoonScreen({super.key, this.title = 'Sắp ra mắt'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SkCard(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 64),
                const SizedBox(height: 18),
                Text(title, style: const TextStyle(color: AppColors.textDark, fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text('Tính năng đang được hoàn thiện.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textGrey)),
                const SizedBox(height: 18),
                SkPrimaryButton(label: 'Quay lại', icon: Icons.arrow_back_rounded, onPressed: () => Navigator.pop(context)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
