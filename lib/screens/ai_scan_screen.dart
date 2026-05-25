import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import 'package:image_picker/image_picker.dart';

final ImagePicker _picker = ImagePicker();

class AiScanScreen extends StatefulWidget {
  const AiScanScreen({super.key});

  @override
  State<AiScanScreen> createState() => _AiScanScreenState();
}

class _AiScanScreenState extends State<AiScanScreen> {
  bool _scanning = false;
  bool _saving = false;

  Map<String, dynamic>? _result;
  List<dynamic> _items = [];
  int? _scanResultId;
  String _mealType = 'breakfast';

  num _num(dynamic value, [num fallback = 0]) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Future<void> _scanMeal() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
      maxWidth: 1200,
    );

    if (image == null) return;

    setState(() {
      _scanning = true;
      _result = null;
      _items = [];
      _scanResultId = null;
    });

    try {
      final data = await ApiService.scanMealWithImage(image);

      if (!mounted) return;

      setState(() {
        _result = data;
        _scanResultId = data['scan_result_id'] is int
            ? data['scan_result_id'] as int
            : int.tryParse(data['scan_result_id']?.toString() ?? '');

        _items = data['items'] is List ? data['items'] as List : [];
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi scan: $e')));
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _confirm() async {
    final id = _scanResultId;

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có kết quả AI để lưu')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final result = await ApiService.confirmScanResult(
        id,
        mealType: _mealType,
      );

      if (!mounted) return;

      if (result['success'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Không lưu được bữa ăn AI'),
          ),
        );
      } else {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final calories = _num(_result?['estimated_calories']);
    final protein = _num(_result?['estimated_protein']);
    final carbs = _num(_result?['estimated_carbs']);
    final fat = _num(_result?['estimated_fat']);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          children: [
            _header(),
            const SizedBox(height: 16),
            _cameraMockCard(),
            const SizedBox(height: 16),
            _mealTypeCard(),
            const SizedBox(height: 16),
            if (_result != null) ...[
              _resultCard(calories, protein, carbs, fat),
              const SizedBox(height: 16),
              _itemsCard(),
              const SizedBox(height: 16),
              _confirmButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.arrow_back, size: 21),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'AI quét món ăn',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _cameraMockCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            height: 190,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: Icon(
                Icons.camera_alt_rounded,
                size: 72,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Demo AI Scanner',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bản này dùng mock AI để demo luồng: scan ảnh → nhận calo/macro → xác nhận lưu bữa ăn.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textGrey, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _scanning ? null : _scanMeal,
              icon: _scanning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _scanning ? 'AI đang phân tích...' : 'Quét món ăn mẫu',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mealTypeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _pill('breakfast', 'Sáng'),
          _pill('lunch', 'Trưa'),
          _pill('dinner', 'Tối'),
          _pill('snack', 'Bữa phụ'),
        ],
      ),
    );
  }

  Widget _pill(String value, String label) {
    final active = _mealType == value;

    return GestureDetector(
      onTap: () => setState(() => _mealType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textGrey,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _resultCard(num calories, num protein, num carbs, num fat) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kết quả AI ước tính',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${calories.toStringAsFixed(0)} kcal',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _macro('Protein', protein, AppColors.protein)),
              Expanded(child: _macro('Carb', carbs, AppColors.carbs)),
              Expanded(child: _macro('Fat', fat, AppColors.fat)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macro(String label, num value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
        ),
        const SizedBox(height: 5),
        Text(
          '${value.toStringAsFixed(0)}g',
          style: TextStyle(color: color, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _itemsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Món AI nhận diện',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ..._items.map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.restaurant, color: AppColors.primary),
              title: Text(
                map['name']?.toString() ??
                    map['detected_food_name']?.toString() ??
                    'Món ăn',
              ),
              subtitle: Text(
                '${_num(map['amount'] ?? map['estimated_amount']).toStringAsFixed(0)}${map['unit'] ?? map['estimated_unit'] ?? 'g'}',
              ),
              trailing: Text(
                '${_num(map['calories'] ?? map['estimated_calories']).toStringAsFixed(0)} kcal',
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _confirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _saving ? null : _confirm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
          ),
        ),
        child: Text(
          _saving ? 'Đang lưu...' : 'Xác nhận và lưu bữa ăn',
          style: const TextStyle(fontWeight: FontWeight.w800),
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
