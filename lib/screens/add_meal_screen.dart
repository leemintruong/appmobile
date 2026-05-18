import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/app_events.dart';

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

  num _num(dynamic v, {num fallback = 0}) {
    if (v is num) return v;
    if (v != null) return num.tryParse(v.toString()) ?? fallback;
    return fallback;
  }

  String _str(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    final s = v.toString();
    return s.isEmpty ? fallback : s;
  }

  num _baseAmount(Map<String, dynamic> food) {
    final base = _num(food['base_amount'], fallback: 0);
    if (base > 0) return base;
    final serving = _num(food['serving_size'], fallback: 0);
    return serving > 0 ? serving : 100;
  }

  String _baseUnit(Map<String, dynamic> food) {
    return _str(food['base_unit'], fallback: _str(food['serving_unit'], fallback: 'g'));
  }

  num _defaultAmount(Map<String, dynamic> food) {
    final serving = _num(food['serving_size'], fallback: 0);
    if (serving > 0) return serving;
    return _baseAmount(food);
  }

  num _calcTotal(Map<String, dynamic> item, String key) {
    final nutrient = _num(item[key]);
    final amount = _num(item['amount']);
    final baseAmount = _num(item['base_amount'], fallback: 100);
    if (baseAmount <= 0) return 0;
    return nutrient * amount / baseAmount;
  }

  Future<void> _searchFoods(String keyword) async {
    setState(() => _loading = true);

    try {
      final results = await ApiService.searchFoods(search: keyword.trim(), limit: 80);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được thực phẩm: $e')),
      );
    }
  }

  void _addFood(Map<String, dynamic> food) {
    final foodId = food['id'];
    final existingIndex = _selectedItems.indexWhere((item) => item['food_id'] == foodId);
    final addAmount = _defaultAmount(food);

    setState(() {
      if (existingIndex >= 0) {
        final oldAmount = _num(_selectedItems[existingIndex]['amount']);
        _selectedItems[existingIndex]['amount'] = oldAmount + addAmount;
      } else {
        _selectedItems.add({
          'food_id': foodId,
          'food_name': food['name'],
          'amount': addAmount,
          'amount_unit': _baseUnit(food),
          'calories': food['calories'] ?? 0,
          'protein': food['protein'] ?? 0,
          'carbs': food['carbs'] ?? 0,
          'fat': food['fat'] ?? 0,
          'base_amount': _baseAmount(food),
          'base_unit': _baseUnit(food),
        });
      }
    });
  }

  void _removeFood(Map<String, dynamic> item) {
    setState(() => _selectedItems.remove(item));
  }

  void _changeAmount(Map<String, dynamic> item, num delta) {
    setState(() {
      final current = _num(item['amount']);
      final next = current + delta;
      item['amount'] = next <= 0 ? current : next;
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
        return {
          'food_id': item['food_id'],
          'amount': _num(item['amount']).toDouble(),
          'amount_unit': item['amount_unit'],
        };
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

      AppEvents.notifyDataChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu bữa ăn và cập nhật trang chủ')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  num get _totalCalories {
    return _selectedItems.fold<num>(0, (sum, item) => sum + _calcTotal(item, 'calories'));
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
              child: const Icon(Icons.arrow_back, size: 21, color: AppColors.textDark),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Thêm bữa ăn',
              style: TextStyle(color: AppColors.textDark, fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
            child: const Icon(Icons.restaurant, color: AppColors.primary, size: 21),
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
          const Text('Loại bữa ăn', style: TextStyle(color: AppColors.textDark, fontSize: 17, fontWeight: FontWeight.w600)),
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
        onTap: () => setState(() => _mealType = value),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(color: selected ? Colors.white : AppColors.textGrey, fontSize: 13, fontWeight: FontWeight.w700),
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
          const Text('Tìm thực phẩm', style: TextStyle(color: AppColors.textDark, fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            onSubmitted: _searchFoods,
            decoration: InputDecoration(
              hintText: 'Nhập tên món: cơm, gà, trứng...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _searchFoods(_searchCtrl.text),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.border)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _foodListCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Danh sách thực phẩm', style: TextStyle(color: AppColors.textDark, fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(18), child: CircularProgressIndicator(color: AppColors.primary)))
          else if (_foods.isEmpty)
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text('Chưa có thực phẩm phù hợp', style: TextStyle(color: AppColors.textGrey)),
            )
          else
            ..._foods.take(10).map((food) => _foodRow(Map<String, dynamic>.from(food))),
        ],
      ),
    );
  }

  Widget _foodRow(Map<String, dynamic> food) {
    final name = _str(food['name'], fallback: 'Món ăn');
    final kcal = _num(food['calories']);
    final baseAmount = _baseAmount(food);
    final baseUnit = _baseUnit(food);
    final source = _str(food['source_name']);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primarySoft,
            child: Icon(Icons.restaurant_menu, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${kcal.toStringAsFixed(0)} kcal / ${baseAmount.toStringAsFixed(0)}$baseUnit', style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                if (source.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(source, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.primaryDark, fontSize: 11)),
                ],
              ],
            ),
          ),
          IconButton(onPressed: () => _addFood(food), icon: const Icon(Icons.add_circle, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _selectedCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Món đã chọn', style: TextStyle(color: AppColors.textDark, fontSize: 17, fontWeight: FontWeight.w600))),
              Text('${_totalCalories.toStringAsFixed(0)} kcal', style: const TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          if (_selectedItems.isEmpty)
            const Padding(padding: EdgeInsets.all(14), child: Text('Chưa chọn món nào', style: TextStyle(color: AppColors.textGrey)))
          else
            ..._selectedItems.map((item) => _selectedRow(item)),
        ],
      ),
    );
  }

  Widget _selectedRow(Map<String, dynamic> item) {
    final name = _str(item['food_name'], fallback: 'Món ăn');
    final amount = _num(item['amount']);
    final unit = _str(item['amount_unit'], fallback: 'g');
    final total = _calcTotal(item, 'calories');
    final step = _num(item['base_amount'], fallback: 100);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                Text('${amount.toStringAsFixed(0)}$unit · ${total.toStringAsFixed(0)} kcal', style: const TextStyle(color: AppColors.primaryDark, fontSize: 12)),
              ],
            ),
          ),
          IconButton(onPressed: () => _changeAmount(item, -step), icon: const Icon(Icons.remove_circle_outline, color: AppColors.textGrey)),
          IconButton(onPressed: () => _changeAmount(item, step), icon: const Icon(Icons.add_circle_outline, color: AppColors.primary)),
          IconButton(onPressed: () => _removeFood(item), icon: const Icon(Icons.close, color: AppColors.textGrey)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        child: _saving
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4))
            : const Text('Lưu bữa ăn', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.035), blurRadius: 20, offset: const Offset(0, 8))],
    );
  }
}
