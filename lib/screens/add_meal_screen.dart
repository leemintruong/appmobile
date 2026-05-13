import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';

class AddMealScreen extends StatefulWidget {
  const AddMealScreen({super.key});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  String _mealType = 'breakfast';

  final TextEditingController _searchCtrl = TextEditingController();

  List<dynamic> _foods = [];
  final List<Map<String, dynamic>> _selectedItems = [];

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _searchFoods('');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchFoods(String keyword) async {
    setState(() {
      _loading = true;
    });

    try {
      final results = await ApiService.searchFoods(search: keyword.trim());

      if (!mounted) return;

      setState(() {
        _foods = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _foods = [];
        _loading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không tải được thực phẩm: $e')));
    }
  }

  void _addFood(Map<String, dynamic> food) {
    final existingIndex = _selectedItems.indexWhere(
      (item) => item['food_id'] == food['id'],
    );

    setState(() {
      if (existingIndex >= 0) {
        final oldQty =
            num.tryParse(
              _selectedItems[existingIndex]['quantity'].toString(),
            ) ??
            0;

        _selectedItems[existingIndex]['quantity'] = oldQty + 100;
      } else {
        _selectedItems.add({
          'food_id': food['id'],
          'food_name': food['name'],
          'quantity': 100,
          'calories': food['calories'] ?? 0,
          'protein': food['protein'] ?? 0,
          'carbs': food['carbs'] ?? 0,
          'fat': food['fat'] ?? 0,
          'serving_unit': food['serving_unit'] ?? 'g',
        });
      }
    });
  }

  void _removeFood(Map<String, dynamic> item) {
    setState(() {
      _selectedItems.remove(item);
    });
  }

  Future<void> _saveMeal() async {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một món')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final items = _selectedItems.map((item) {
        return {'food_id': item['food_id'], 'quantity': item['quantity']};
      }).toList();

      final result = await ApiService.addMeal(
        mealType: _mealType,
        items: items,
      );

      if (!mounted) return;

      if (result['success'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Không lưu được bữa ăn')),
        );
        return;
      }

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  num get _totalCalories {
    return _selectedItems.fold<num>(0, (sum, item) {
      final calories = num.tryParse(item['calories'].toString()) ?? 0;
      final quantity = num.tryParse(item['quantity'].toString()) ?? 0;

      return sum + (calories / 100) * quantity;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _topHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _mealTypeCard(),
                    const SizedBox(height: 16),
                    _searchCard(),
                    const SizedBox(height: 16),
                    _foodListCard(),
                    const SizedBox(height: 16),
                    _selectedCard(),
                    const SizedBox(height: 16),
                    _saveButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Row(
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
              child: const Icon(
                Icons.arrow_back,
                size: 21,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Thêm bữa ăn',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant,
              color: AppColors.primary,
              size: 21,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Loại bữa ăn',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _mealTypePill('breakfast', 'Sáng'),
              const SizedBox(width: 8),
              _mealTypePill('lunch', 'Trưa'),
              const SizedBox(width: 8),
              _mealTypePill('dinner', 'Tối'),
              const SizedBox(width: 8),
              _mealTypePill('snack', 'Snack'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mealTypePill(String value, String label) {
    final selected = _mealType == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _mealType = value;
          });
        },
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textGrey,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tìm thực phẩm',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            onChanged: _searchFoods,
            decoration: InputDecoration(
              hintText: 'Tìm món ăn hoặc thực phẩm...',
              hintStyle: const TextStyle(
                color: AppColors.textLight,
                fontSize: 14,
              ),
              prefixIcon: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : const Icon(Icons.search, color: AppColors.textGrey),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _foodListCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Thư viện thực phẩm',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${_foods.length} món',
                style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_foods.isEmpty)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Center(
                child: Text(
                  'Không tìm thấy thực phẩm',
                  style: TextStyle(color: AppColors.textGrey),
                ),
              ),
            )
          else
            ..._foods.take(8).map((food) {
              final f = food as Map<String, dynamic>;
              return _foodRow(f);
            }),
        ],
      ),
    );
  }

  Widget _foodRow(Map<String, dynamic> food) {
    final name = food['name']?.toString() ?? 'Thực phẩm';
    final calories = food['calories']?.toString() ?? '0';
    final protein = food['protein']?.toString() ?? '0';
    final carbs = food['carbs']?.toString() ?? '0';
    final fat = food['fat']?.toString() ?? '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Center(
              child: Text('🍽️', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$calories kcal · P $protein · C $carbs · F $fat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _addFood(food),
            icon: const Icon(
              Icons.add_circle,
              color: AppColors.primary,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectedCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Món đã chọn',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${_totalCalories.toStringAsFixed(0)} kcal',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_selectedItems.isEmpty)
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Chưa chọn món nào',
                style: TextStyle(color: AppColors.textGrey),
              ),
            )
          else
            ..._selectedItems.map((item) => _selectedRow(item)),
        ],
      ),
    );
  }

  Widget _selectedRow(Map<String, dynamic> item) {
    final name = item['food_name']?.toString() ?? 'Món ăn';
    final qty = num.tryParse(item['quantity'].toString()) ?? 0;
    final unit = item['serving_unit']?.toString() ?? 'g';
    final calories = num.tryParse(item['calories'].toString()) ?? 0;
    final total = (calories / 100) * qty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Text('🥣', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
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
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${qty.toStringAsFixed(0)}$unit · ${total.toStringAsFixed(0)} kcal',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeFood(item),
            icon: const Icon(Icons.close, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _saving ? null : _saveMeal,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: _saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : const Text(
                'Lưu bữa ăn',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
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
