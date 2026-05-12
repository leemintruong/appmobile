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
  final _searchCtrl = TextEditingController();

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
    setState(() => _loading = true);

    try {
      final foods = await ApiService.searchFoods(search: keyword.trim());

      if (!mounted) return;

      setState(() {
        _foods = foods;
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
      ).showSnackBar(SnackBar(content: Text('Không tải được món ăn: $e')));
    }
  }

  void _addFood(Map<String, dynamic> food) {
    final existingIndex = _selectedItems.indexWhere(
      (item) => item['food_id'] == food['id'],
    );

    setState(() {
      if (existingIndex >= 0) {
        _selectedItems[existingIndex]['quantity'] =
            (_selectedItems[existingIndex]['quantity'] as num) + 100;
      } else {
        _selectedItems.add({
          'food_id': food['id'],
          'food_name': food['name'],
          'quantity': 100,
          'calories': food['calories'] ?? 0,
          'serving_unit': food['serving_unit'] ?? 'g',
        });
      }
    });
  }

  num get _selectedTotalCalories {
    return _selectedItems.fold<num>(0, (sum, item) {
      final cal = num.tryParse(item['calories'].toString()) ?? 0;
      final qty = num.tryParse(item['quantity'].toString()) ?? 0;
      return sum + (cal / 100) * qty;
    });
  }

  Future<void> _saveMeal() async {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một món')),
      );
      return;
    }

    setState(() => _saving = true);

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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageGrey,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
          children: [
            const Text(
              'Thêm bữa ăn',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 26),

            const Text(
              'Chọn loại bữa',
              style: TextStyle(
                color: AppColors.textGrey,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                _mealPill('breakfast', 'Sáng'),
                _mealPill('lunch', 'Trưa'),
                _mealPill('dinner', 'Tối'),
                _mealPill('snack', 'Phụ'),
              ],
            ),

            const SizedBox(height: 26),

            const Text(
              'Tìm món ăn',
              style: TextStyle(
                color: AppColors.textGrey,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _searchCtrl,
              onChanged: _searchFoods,
              decoration: InputDecoration(
                hintText: 'Nhập tên món: cơm, phở, trứng...',
                hintStyle: const TextStyle(color: AppColors.textLight),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Kết quả tìm kiếm',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),

            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_foods.isEmpty)
              const Text(
                'Không tìm thấy món ăn',
                style: TextStyle(color: AppColors.textGrey),
              )
            else
              ..._foods.take(5).map((food) {
                final f = food as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _foodCard(f),
                );
              }),

            const SizedBox(height: 20),

            const Text(
              'Món đã chọn',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),

            if (_selectedItems.isEmpty)
              const Text(
                'Chưa chọn món nào',
                style: TextStyle(color: AppColors.textGrey),
              )
            else
              ..._selectedItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _selectedCard(item),
                );
              }),

            const SizedBox(height: 28),

            SizedBox(
              height: 58,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveMeal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Lưu bữa ăn',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mealPill(String value, String label) {
    final selected = _mealType == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mealType = value),
        child: Container(
          height: 42,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.softGreen
                : Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primaryDark : AppColors.textGrey,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _foodCard(Map<String, dynamic> food) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food['name']?.toString() ?? 'Món ăn',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${food['calories'] ?? 0} kcal / 100g',
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _addFood(food),
            icon: const Icon(Icons.add, color: AppColors.primary, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _selectedCard(Map<String, dynamic> item) {
    final cal = num.tryParse(item['calories'].toString()) ?? 0;
    final qty = num.tryParse(item['quantity'].toString()) ?? 0;
    final total = (cal / 100) * qty;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.softGreen2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB8F3C8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['food_name']?.toString() ?? 'Món ăn',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Số lượng: ${(item['quantity'] as num).toStringAsFixed(0)} x ${item['serving_unit']}',
                  style: const TextStyle(
                    color: Color(0xFF047857),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${total.toStringAsFixed(0)} kcal',
            style: const TextStyle(
              color: Color(0xFF047857),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
