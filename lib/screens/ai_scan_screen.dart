import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/app_events.dart';
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

  Future<void> _scanMeal({ImageSource source = ImageSource.camera}) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 45,
      maxWidth: 700,
      maxHeight: 700,
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

  Future<void> _addItemToFoodLibrary(Map<String, dynamic> item) async {
    final scanId = _scanResultId;
    final itemId = int.tryParse(
      '${item['id'] ?? item['ai_scan_result_item_id'] ?? item['item_id'] ?? ''}',
    );

    if (scanId == null || itemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không xác định được món AI để thêm')),
      );
      return;
    }

    try {
      final result = await ApiService.addAIResultItemToFoods(
        scanResultId: scanId,
        itemId: itemId,
      );

      if (!mounted) return;

      if (result['success'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Không thêm được vào thư viện')),
        );
        return;
      }

      final food = result['food'];
      final newFoodId = result['food_id'] ??
          result['id'] ??
          (food is Map ? food['id'] : null);

      setState(() {
        for (final raw in _items) {
          if (raw is Map && '${raw['id'] ?? raw['ai_scan_result_item_id'] ?? raw['item_id']}' == '$itemId') {
            raw['matched_food_id'] = newFoodId ?? raw['matched_food_id'] ?? 1;
          }
        }
      });

      AppEvents.notifyDataChanged();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm món AI vào thư viện thực phẩm')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi thêm vào thư viện: $e')),
      );
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
        date: ApiService.todayString(),
      );

      if (!mounted) return;

      if (result['success'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Không lưu được bữa ăn AI'),
          ),
        );
      } else {
        AppEvents.notifyDataChanged();
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
            'AI Scanner thật',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Chụp hoặc chọn ảnh món ăn. AI sẽ ước tính calo/macro, sau đó bạn kiểm tra và xác nhận trước khi lưu.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textGrey, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _scanning ? null : () => _scanMeal(source: ImageSource.camera),
                    icon: _scanning
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.photo_camera),
                    label: Text(_scanning ? 'Đang phân tích...' : 'Chụp ảnh'),
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
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _scanning ? null : () => _scanMeal(source: ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Chọn ảnh'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
          const SizedBox(height: 6),
          const Text(
            'Nếu món chưa có trong thư viện, bạn có thể thêm để dùng lại sau.',
            style: TextStyle(color: AppColors.textGrey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ..._items.map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            final name = map['name']?.toString() ??
                map['detected_food_name']?.toString() ??
                'Món ăn';
            final amount = _num(map['amount'] ?? map['estimated_amount']);
            final unit = map['unit'] ?? map['estimated_unit'] ?? 'g';
            final kcal = _num(map['calories'] ?? map['estimated_calories']);
            final matchedFoodId = int.tryParse('${map['matched_food_id'] ?? map['food_id'] ?? ''}');
            final canAdd = matchedFoodId == null || matchedFoodId <= 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        canAdd ? Icons.auto_awesome : Icons.check_circle,
                        color: canAdd ? AppColors.warning : AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '${kcal.toStringAsFixed(0)} kcal',
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 1)}$unit',
                          style: const TextStyle(color: AppColors.textGrey),
                        ),
                      ),
                      if (canAdd)
                        TextButton.icon(
                          onPressed: () => _addItemToFoodLibrary(map),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Thêm vào thư viện'),
                        )
                      else
                        const Text(
                          'Đã có trong thư viện',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                        ),
                    ],
                  ),
                ],
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
