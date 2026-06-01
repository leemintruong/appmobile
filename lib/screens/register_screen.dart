import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/sk_ui.dart';
import 'profile_setup_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _agree = true;
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _toast('Vui lòng nhập đầy đủ thông tin');
      return;
    }
    if (password.length < 6) {
      _toast('Mật khẩu cần ít nhất 6 ký tự');
      return;
    }
    if (!_agree) {
      _toast('Bạn cần đồng ý điều khoản');
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await ApiService.register(name, email, password);
      if (!mounted) return;
      if (result['success'] == true || result['token'] != null) {
        final token = result['token'];
        if (token != null) await ApiService.saveToken(token.toString());
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfileSetupScreen()));
      } else {
        _toast(result['message'] ?? 'Đăng ký không thành công');
      }
    } catch (e) {
      if (mounted) _toast('Không kết nối được máy chủ: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
          children: [
            Row(
              children: [
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
                const SizedBox(width: 4),
                const Text('Tạo tài khoản', style: TextStyle(color: AppColors.textDark, fontSize: 26, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 12),
            SkFadeSlide(child: _intro()),
            const SizedBox(height: 18),
            SkFadeSlide(delayMs: 80, child: _form()),
          ],
        ),
      ),
    );
  }

  Widget _intro() {
    return SkCard(
      color: AppColors.primarySoft,
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(.12), borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.spa_rounded, color: AppColors.primary, size: 40),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text('Bắt đầu hành trình dinh dưỡng cá nhân chỉ trong vài bước.', style: TextStyle(color: AppColors.primaryDark, fontSize: 15, height: 1.4, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _form() {
    return SkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkTextField(controller: _nameCtrl, label: 'Họ tên', hint: 'Nguyễn Văn A'),
          const SizedBox(height: 16),
          SkTextField(controller: _emailCtrl, label: 'Email', hint: 'email@example.com', keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),
          SkTextField(
            controller: _passCtrl,
            label: 'Mật khẩu',
            hint: 'Tối thiểu 6 ký tự',
            obscure: _obscure,
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: AppColors.textLight),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Switch(value: _agree, activeColor: AppColors.primary, onChanged: (v) => setState(() => _agree = v)),
              const Expanded(child: Text('Tôi đồng ý với điều khoản sử dụng', style: TextStyle(color: AppColors.textGrey))),
            ],
          ),
          const SizedBox(height: 14),
          SkPrimaryButton(label: 'Tiếp tục', icon: Icons.arrow_forward_rounded, onPressed: _register, loading: _loading),
        ],
      ),
    );
  }
}
