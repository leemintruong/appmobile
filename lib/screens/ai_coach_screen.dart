import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class AiCoachScreen extends StatefulWidget {
  final bool showBackButton;

  const AiCoachScreen({super.key, this.showBackButton = true});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  final TextEditingController _messageCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  bool _loading = false;
  final List<_CoachMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _messages.add(
      _CoachMessage(
        role: 'ai',
        text:
            'Chào bạn, mình là AI Coach dinh dưỡng. Mình có thể xem dữ liệu ăn uống hôm nay và gợi ý bạn nên ăn thêm gì để đạt mục tiêu.',
      ),
    );
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    final message = text.trim();
    if (message.isEmpty || _loading) return;

    setState(() {
      _messages.add(_CoachMessage(role: 'user', text: message));
      _loading = true;
      _messageCtrl.clear();
    });

    _scrollToBottom();

    try {
      final result = await ApiService.askHealthAi(message: message);

      final answer = result['answer']?.toString() ??
          result['message']?.toString() ??
          'Mình chưa thể trả lời lúc này.';

      if (!mounted) return;
      setState(() {
        _messages.add(_CoachMessage(role: 'ai', text: answer));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _CoachMessage(
            role: 'ai',
            text: 'Mình chưa kết nối được AI Coach. Lỗi: $e',
          ),
        );
      });
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  Future<void> _suggestMeal(String mealType) async {
    if (_loading) return;

    final label = _mealTypeLabel(mealType);

    setState(() {
      _messages.add(_CoachMessage(role: 'user', text: 'Gợi ý $label cho hôm nay'));
      _loading = true;
    });

    _scrollToBottom();

    try {
      final result = await ApiService.suggestMealWithAi(mealType: mealType);

      final answer = result['answer']?.toString() ??
          result['message']?.toString() ??
          'Mình chưa gợi ý được bữa ăn lúc này.';

      if (!mounted) return;
      setState(() {
        _messages.add(_CoachMessage(role: 'ai', text: answer));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _CoachMessage(
            role: 'ai',
            text: 'Mình chưa lấy được gợi ý bữa ăn. Lỗi: $e',
          ),
        );
      });
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  String _mealTypeLabel(String type) {
    switch (type) {
      case 'breakfast':
        return 'bữa sáng';
      case 'lunch':
        return 'bữa trưa';
      case 'dinner':
        return 'bữa tối';
      case 'snack':
        return 'bữa phụ';
      default:
        return 'bữa ăn';
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _quickActions(),
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: _messages.length + (_loading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_loading && index == _messages.length) {
                    return const _TypingBubble();
                  }
                  return _messageBubble(_messages[index]);
                },
              ),
            ),
            _inputBar(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          if (widget.showBackButton) ...[
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.arrow_back, color: AppColors.textDark),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'AI Coach dinh dưỡng',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Hỏi đáp và gợi ý bữa ăn theo dữ liệu của bạn',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.psychology_alt, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _quickActions() {
    final chips = [
      ['Hôm nay tôi còn thiếu gì?', null],
      ['Tôi nên ăn thêm gì?', null],
      ['Gợi ý bữa phụ', 'snack'],
      ['Gợi ý bữa tối', 'dinner'],
    ];

    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final label = chips[index][0]!;
          final mealType = chips[index][1];

          return ActionChip(
            label: Text(label),
            avatar: Icon(
              mealType == null ? Icons.auto_awesome : Icons.restaurant,
              size: 17,
              color: AppColors.primary,
            ),
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppColors.border),
            labelStyle: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w700,
            ),
            onPressed: () {
              if (mealType == null) {
                _sendMessage(label);
              } else {
                _suggestMeal(mealType);
              }
            },
          );
        },
      ),
    );
  }

  Widget _messageBubble(_CoachMessage message) {
    final isUser = message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 6),
            bottomRight: Radius.circular(isUser ? 6 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : AppColors.textDark,
            fontSize: 14,
            height: 1.38,
          ),
        ),
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageCtrl,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: _sendMessage,
              decoration: InputDecoration(
                hintText: 'Hỏi AI: hôm nay tôi nên ăn gì?',
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(_messageCtrl.text),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _loading ? AppColors.textLight : AppColors.primary,
                borderRadius: BorderRadius.circular(23),
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachMessage {
  final String role;
  final String text;

  const _CoachMessage({required this.role, required this.text});
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Text(
          'AI đang phân tích dữ liệu của bạn...',
          style: TextStyle(color: AppColors.textGrey),
        ),
      ),
    );
  }
}
