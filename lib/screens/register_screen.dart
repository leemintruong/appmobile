import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
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
  final _confirmPassCtrl = TextEditingController();

  bool _agree = false;
  bool _isLoading = false;

  bool _nameTouched = false;
  bool _emailTouched = false;
  bool _passwordTouched = false;
  bool _confirmTouched = false;

  String? _emailErrorFromServer;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  bool get _isNameValid {
    return _nameCtrl.text.trim().length >= 2;
  }

  bool get _isEmailOrPhoneValid {
    final value = _emailCtrl.text.trim();

    if (value.isEmpty) return false;

    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    final phoneRegex = RegExp(r'^(0|\+84)[0-9]{9,10}$');

    return emailRegex.hasMatch(value) || phoneRegex.hasMatch(value);
  }

  bool get _hasMinLength {
    return _passCtrl.text.trim().length >= 8;
  }

  bool get _hasUpperAndNumber {
    final text = _passCtrl.text.trim();
    return RegExp(r'[A-Z]').hasMatch(text) && RegExp(r'[0-9]').hasMatch(text);
  }

  bool get _noSpace {
    final text = _passCtrl.text;
    return text.isNotEmpty && !text.contains(' ');
  }

  bool get _isPasswordValid {
    return _hasMinLength && _hasUpperAndNumber && _noSpace;
  }

  bool get _confirmMatch {
    return _confirmPassCtrl.text.isNotEmpty &&
        _passCtrl.text.trim() == _confirmPassCtrl.text.trim();
  }

  Future<void> _handleRegister() async {
    setState(() {
      _nameTouched = true;
      _emailTouched = true;
      _passwordTouched = true;
      _confirmTouched = true;
      _emailErrorFromServer = null;
    });

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();
    final confirm = _confirmPassCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showMessage('Vui lòng nhập đầy đủ thông tin');
      return;
    }

    if (!_isNameValid) {
      _showMessage('Họ tên quá ngắn');
      return;
    }

    if (!_isEmailOrPhoneValid) {
      _showMessage('Email hoặc số điện thoại không đúng định dạng');
      return;
    }

    if (!_isPasswordValid) {
      _showMessage('Mật khẩu chưa đủ mạnh');
      return;
    }

    if (!_confirmMatch) {
      _showMessage('Mật khẩu không trùng khớp');
      return;
    }

    if (!_agree) {
      _showMessage('Vui lòng đồng ý với điều khoản dịch vụ');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final registerResult = await ApiService.register(name, email, password);

      if (!mounted) return;

      if (registerResult['success'] == false) {
        final message = registerResult['message'] ?? 'Đăng ký thất bại';

        setState(() {
          if (message.toLowerCase().contains('email') ||
              message.toLowerCase().contains('sử dụng') ||
              message.toLowerCase().contains('trùng')) {
            _emailErrorFromServer = message;
          }
        });

        _showMessage(message);
        return;
      }

      final loginResult = await ApiService.login(email, password);

      if (!mounted) return;

      if (loginResult['token'] != null || loginResult['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('Không kết nối được máy chủ: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _registerCard(),
                    const SizedBox(height: 22),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 15,
                          ),
                          children: [
                            TextSpan(text: 'Đã có tài khoản?  '),
                            TextSpan(
                              text: 'Quay lại Đăng nhập',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                ),
              ),
            ),
            _bottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
      child: Row(
        children: [
          const Icon(Icons.favorite, color: AppColors.primary, size: 24),
          const SizedBox(width: 8),
          const Text(
            'SứcKhỏe',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 23,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text(
              'Đăng nhập',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _registerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(26, 28, 26, 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tạo tài khoản',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 28,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Tạo tài khoản mới để bắt đầu theo dõi sức khỏe và bữa ăn hằng ngày.',
            style: TextStyle(
              color: AppColors.textGrey,
              fontSize: 15,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 26),

          _label('Họ & Tên'),
          const SizedBox(height: 8),
          _input(
            controller: _nameCtrl,
            hint: 'Nguyễn Văn A',
            onChanged: (_) {
              setState(() {
                _nameTouched = true;
              });
            },
          ),
          if (_nameTouched && _nameCtrl.text.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              _isNameValid ? 'Tên hợp lệ' : 'Tên quá ngắn',
              style: TextStyle(
                color: _isNameValid ? AppColors.primary : AppColors.danger,
                fontSize: 13,
              ),
            ),
          ],

          const SizedBox(height: 18),

          _label('Email hoặc Số điện thoại'),
          const SizedBox(height: 8),
          _input(
            controller: _emailCtrl,
            hint: 'email@domain.com hoặc 0912345678',
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) {
              setState(() {
                _emailTouched = true;
                _emailErrorFromServer = null;
              });
            },
          ),
          if (_emailTouched &&
              _emailCtrl.text.trim().isNotEmpty &&
              !_isEmailOrPhoneValid) ...[
            const SizedBox(height: 7),
            const Text(
              'Email hoặc số điện thoại không đúng định dạng',
              style: TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ],
          if (_emailErrorFromServer != null) ...[
            const SizedBox(height: 7),
            Text(
              _emailErrorFromServer!,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ],

          const SizedBox(height: 18),

          Row(
            children: [
              _label('Mật khẩu'),
              const Spacer(),
              const Text(
                'Ẩn',
                style: TextStyle(color: AppColors.textGrey, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _input(
            controller: _passCtrl,
            hint: 'Tạo mật khẩu mạnh',
            obscure: true,
            onChanged: (_) {
              setState(() {
                _passwordTouched = true;
              });
            },
          ),
          if (_passwordTouched && _passCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            _rule(_hasMinLength, 'Ít nhất 8 ký tự'),
            const SizedBox(height: 8),
            _rule(_hasUpperAndNumber, 'Có chữ hoa và số'),
            const SizedBox(height: 8),
            _rule(_noSpace, 'Không chứa khoảng trắng'),
          ],

          const SizedBox(height: 18),

          _label('Xác nhận mật khẩu'),
          const SizedBox(height: 8),
          _input(
            controller: _confirmPassCtrl,
            hint: 'Nhập lại mật khẩu',
            obscure: true,
            borderColor: !_confirmTouched || _confirmPassCtrl.text.isEmpty
                ? AppColors.inputBorder
                : (_confirmMatch ? AppColors.primary : AppColors.danger),
            onChanged: (_) {
              setState(() {
                _confirmTouched = true;
              });
            },
          ),
          if (_confirmTouched &&
              _confirmPassCtrl.text.isNotEmpty &&
              !_confirmMatch) ...[
            const SizedBox(height: 7),
            const Text(
              'Mật khẩu không trùng khớp',
              style: TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ],

          const SizedBox(height: 18),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => setState(() => _agree = !_agree),
                child: Container(
                  width: 23,
                  height: 23,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: AppColors.inputBorder,
                      width: 1.2,
                    ),
                    color: _agree ? AppColors.primary : Colors.white,
                  ),
                  child: _agree
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 13,
                    ),
                    children: [
                      TextSpan(text: 'Tôi đồng ý với '),
                      TextSpan(
                        text: 'điều khoản dịch vụ',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 26),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : const Text(
                      'Tiếp tục',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textDark,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    Color borderColor = AppColors.inputBorder,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 15),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: borderColor, width: 1.3),
        ),
      ),
    );
  }

  Widget _rule(bool ok, String text) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check : Icons.close,
          color: ok ? AppColors.primary : AppColors.danger,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(color: AppColors.textDark, fontSize: 13),
        ),
      ],
    );
  }

  Widget _bottomNav() {
    return Container(
      height: 66,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomItem(icon: Icons.home, label: 'Trang chủ'),
          _BottomItem(icon: Icons.restaurant, label: 'Bữa ăn'),
          _BottomItem(icon: Icons.show_chart, label: 'Báo cáo'),
          _BottomItem(icon: Icons.person, label: 'Hồ sơ'),
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BottomItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.textGrey, size: 22),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(color: AppColors.textGrey, fontSize: 11),
        ),
      ],
    );
  }
}
