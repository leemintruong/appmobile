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
  final _searchCtrl = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _searching = false;
  bool _saving = false;

  final _mealTypes = [
    ('breakfast', '🌅', 'Sáng'),
    ('lunch', '☀️', 'Trưa'),
    ('dinner', '🌙', 'Tối'),
    ('snack', '🍎', 'Phụ'),
  ];

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      final results = await ApiService.searchFoods();
      setState(() => _searchResults = results);
      return;
    }
    setState(() => _searching = true);
    final results = await ApiService.searchFoods(search: q.trim());
    setState(() {
      _searchResults = results;
      _searching = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _search(''); // load danh sách mặc định
  }

  void _addFood(Map<String, dynamic> food) async {
    final qty = await _showQuantityDialog(food);
    if (qty != null && qty > 0) {
      setState(
        () => _selectedItems.add({
          'food_id': food['id'],
          'food_name': food['name'],
          'quantity': qty,
          'serving_unit': food['serving_unit'] ?? 'g',
          'calories': food['calories'],
        }),
      );
    }
  }

  Future<double?> _showQuantityDialog(Map<String, dynamic> food) async {
    final ctrl = TextEditingController(
      text: (food['serving_size'] ?? 100).toString(),
    );
    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(food['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${food['calories']} kcal / 100g  •  '
              'P: ${food['protein']}g  '
              'C: ${food['carbs']}g  '
              'F: ${food['fat']}g',
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () =>
                Navigator.pop(ctx, double.tryParse(ctrl.text) ?? 0),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  double get _totalCal => _selectedItems.fold(0, (s, item) {
    return s + ((item['calories'] as num).toDouble() / 100) * item['quantity'];
  });

  Future<void> _save() async {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm ít nhất một món')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final items = _selectedItems
          .map((i) => {'food_id': i['food_id'], 'quantity': i['quantity']})
          .toList();
      await ApiService.addMeal(mealType: _mealType, items: items);
      if (mounted) Navigator.pop(context, true); // trả về true → reload Home
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
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
          // ── Chọn loại bữa ──────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: _mealTypes
                  .map(
                    (t) => Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _mealType = t.$1),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _mealType == t.$1
                                ? AppColors.primary
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(t.$2, style: const TextStyle(fontSize: 18)),
                              Text(
                                t.$3,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _mealType == t.$1
                                      ? Colors.white
                                      : AppColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // ── Tìm kiếm ───────────────────────────────────
          Padding(
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // ── Tổng đã chọn ───────────────────────────────
          if (_selectedItems.isNotEmpty)
            Container(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Đã chọn ${_selectedItems.length} món',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
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
                  ..._selectedItems.map(
                    (item) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '• ${item['food_name']}  '
                          '${item['quantity'].round()}'
                          '${item['serving_unit']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textGrey,
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _selectedItems.remove(item)),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // ── Danh sách kết quả ──────────────────────────
          Expanded(
            child: _searchResults.isEmpty
                ? const Center(
                    child: Text(
                      'Không tìm thấy món ăn',
                      style: TextStyle(color: AppColors.textGrey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _searchResults.length,
                    itemBuilder: (_, i) {
                      final food = _searchResults[i];
                      final isAdded = _selectedItems.any(
                        (item) => item['food_id'] == food['id'],
                      );
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isAdded
                              ? AppColors.primary.withOpacity(0.05)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: isAdded
                              ? Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                )
                              : null,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(
                              food['name'][0],
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            food['name'],
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'P: ${food['protein']}g  '
                            'C: ${food['carbs']}g  '
                            'F: ${food['fat']}g',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textGrey,
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${food['calories']} kcal',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                              Text(
                                '/100g',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _addFood(food),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
