import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/sk_ui.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController(text: 'lan@gmail.com');
  final _passCtrl = TextEditingController(text: 'matkhau123');
  bool _obscure = true;
  bool _remember = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) {
      _toast('Vui lòng nhập email và mật khẩu');
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await ApiService.login(_emailCtrl.text.trim(), _passCtrl.text.trim());
      if (!mounted) return;
      if (result['success'] == true || result['token'] != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        _toast(result['message'] ?? 'Đăng nhập không thành công');
      }
    } catch (e) {
      if (mounted) _toast('Không kết nối được máy chủ: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
          children: [
            _brandHeader(),
            const SizedBox(height: 20),
            SkFadeSlide(child: _heroCard()),
            const SizedBox(height: 18),
            SkFadeSlide(delayMs: 80, child: _loginCard()),
            const SizedBox(height: 18),
            Center(
              child: TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: const Text('Chưa có tài khoản? Đăng ký ngay', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brandHeader() {
    return Row(
      children: [
        const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 30),
        const SizedBox(width: 10),
        const Text('SứcKhỏe', style: TextStyle(color: AppColors.primaryDark, fontSize: 30, fontWeight: FontWeight.w900)),
        const Spacer(),
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          child: const Icon(Icons.question_mark_rounded, color: Colors.white, size: 22),
        ),
      ],
    );
  }

  Widget _heroCard() {
    return Container(
      height: 152,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(colors: [Color(0xFFE6FFF3), Color(0xFFFFFFFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: const [BoxShadow(color: AppColors.shadowGreen, blurRadius: 24, offset: Offset(0, 12))],
      ),
      child: Stack(
        children: const [
          Positioned(right: 16, top: 18, child: Icon(Icons.eco_rounded, color: AppColors.secondary, size: 82)),
          Positioned(left: 22, top: 30, child: Text('Chào mừng quay lại', style: TextStyle(color: AppColors.textDark, fontSize: 24, fontWeight: FontWeight.w900))),
          Positioned(left: 22, top: 72, right: 112, child: Text('Theo dõi bữa ăn, năng lượng và tiến trình của bạn.', style: TextStyle(color: AppColors.textGrey, height: 1.35))),
        ],
      ),
    );
  }

  Widget _loginCard() {
    return SkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkTextField(controller: _emailCtrl, label: 'Email', hint: 'email@example.com', keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 18),
          SkTextField(
            controller: _passCtrl,
            label: 'Mật khẩu',
            hint: 'Nhập mật khẩu',
            obscure: _obscure,
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: AppColors.textLight),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _remember = !_remember),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: _remember ? AppColors.primary : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.inputBorder)),
                  child: _remember ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(child: Text('Ghi nhớ đăng nhập', style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.w700))),
              TextButton(onPressed: () {}, child: const Text('Quên mật khẩu?', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w800))),
            ],
          ),
          const SizedBox(height: 18),
          SkPrimaryButton(label: 'Đăng nhập', icon: Icons.login_rounded, onPressed: _login, loading: _loading),
        ],
      ),
    );
  }
}
