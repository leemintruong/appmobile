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

  final List<Map<String, dynamic>> _selectedItems = [];
  final TextEditingController _searchCtrl = TextEditingController();

  List<dynamic> _searchResults = [];
  bool _searching = false;
  bool _saving = false;

  final List<Map<String, String>> _mealTypes = [
    {'value': 'breakfast', 'icon': '🌅', 'label': 'Sáng'},
    {'value': 'lunch', 'icon': '☀️', 'label': 'Trưa'},
    {'value': 'dinner', 'icon': '🌙', 'label': 'Tối'},
    {'value': 'snack', 'icon': '🍎', 'label': 'Phụ'},
  ];

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    try {
      setState(() {
        _searching = true;
      });

      final results = await ApiService.searchFoods(search: q.trim());

      if (!mounted) return;

      setState(() {
        _searchResults = results;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _searchResults = [];
        _searching = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không tải được món ăn: $e')));
    }
  }

  void _addFood(Map<String, dynamic> food) async {
    final qty = await _showQuantityDialog(food);

    if (qty != null && qty > 0) {
      setState(() {
        _selectedItems.add({
          'food_id': food['id'],
          'food_name': food['name'],
          'quantity': qty,
          'serving_unit': food['serving_unit'] ?? 'g',
          'calories': food['calories'] ?? 0,
          'protein': food['protein'] ?? 0,
          'carbs': food['carbs'] ?? 0,
          'fat': food['fat'] ?? 0,
        });
      });
    }
  }

  Future<double?> _showQuantityDialog(Map<String, dynamic> food) async {
    final TextEditingController ctrl = TextEditingController(
      text: (food['serving_size'] ?? 100).toString(),
    );

    return showDialog<double>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(food['name']?.toString() ?? 'Món ăn'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${food['calories'] ?? 0} kcal / 100g  •  '
                'P: ${food['protein'] ?? 0}g  '
                'C: ${food['carbs'] ?? 0}g  '
                'F: ${food['fat'] ?? 0}g',
                style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Số lượng (${food['serving_unit'] ?? 'g'})',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final value = double.tryParse(ctrl.text.trim()) ?? 0;
                Navigator.pop(ctx, value);
              },
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );
  }

  double get _totalCal {
    return _selectedItems.fold(0, (sum, item) {
      final calories = (item['calories'] as num?)?.toDouble() ?? 0;
      final quantity = (item['quantity'] as num?)?.toDouble() ?? 0;

      return sum + (calories / 100) * quantity;
    });
  }

  Future<void> _save() async {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm ít nhất một món')),
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
          SnackBar(
            content: Text(result['message'] ?? 'Không thêm được bữa ăn'),
          ),
        );

        setState(() {
          _saving = false;
        });

        return;
      }

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  bool _isFoodAdded(dynamic foodId) {
    return _selectedItems.any((item) => item['food_id'] == foodId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thêm bữa ăn'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_selectedItems.isNotEmpty)
            TextButton(
              onPressed: _save,
              child: const Text(
                'Lưu',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _mealTypeSelector(),
          _searchBox(),
          if (_selectedItems.isNotEmpty) _selectedFoodBox(),
          const SizedBox(height: 8),
          Expanded(child: _foodResultList()),
        ],
      ),
    );
  }

  Widget _mealTypeSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: _mealTypes.map((type) {
          final value = type['value']!;
          final icon = type['icon']!;
          final label = type['label']!;
          final selected = _mealType == value;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _mealType = value;
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 18)),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: selected ? Colors.white : AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _searchBox() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _search,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm món ăn...',
          prefixIcon: _searching
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _selectedFoodBox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Đã chọn ${_selectedItems.length} món',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Text(
                '${_totalCal.round()} kcal',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ..._selectedItems.map((item) {
            return Row(
              children: [
                Expanded(
                  child: Text(
                    '• ${item['food_name']}  '
                    '${(item['quantity'] as num).toStringAsFixed(0)}'
                    '${item['serving_unit']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedItems.remove(item);
                    });
                  },
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _foodResultList() {
    if (_searching && _searchResults.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Text(
          'Không tìm thấy món ăn',
          style: TextStyle(color: AppColors.textGrey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final food = _searchResults[index] as Map<String, dynamic>;
        final foodName = food['name']?.toString() ?? 'Món ăn';
        final isAdded = _isFoodAdded(food['id']);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isAdded ? AppColors.primary.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: isAdded
                ? Border.all(color: AppColors.primary.withOpacity(0.3))
                : null,
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                foodName.isNotEmpty ? foodName[0] : '?',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              foodName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'P: ${food['protein'] ?? 0}g  '
              'C: ${food['carbs'] ?? 0}g  '
              'F: ${food['fat'] ?? 0}g',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${food['calories'] ?? 0} kcal',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                const Text(
                  '/100g',
                  style: TextStyle(fontSize: 11, color: AppColors.textGrey),
                ),
              ],
            ),
            onTap: () {
              _addFood(food);
            },
          ),
        );
      },
    );
  }
}
