import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';

class FoodListScreen extends StatefulWidget {
  const FoodListScreen({super.key});

  @override
  State<FoodListScreen> createState() => _FoodListScreenState();
}

class _FoodListScreenState extends State<FoodListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  String _selectedCategory = '';
  bool _loading = true;
  List<dynamic> _foods = [];

  final List<Map<String, String>> _categories = const [
    {'label': 'Tất cả', 'value': ''},
    {'label': 'Tinh bột', 'value': 'Tinh bột'},
    {'label': 'Thịt', 'value': 'Thịt'},
    {'label': 'Rau', 'value': 'Rau'},
    {'label': 'Món Việt', 'value': 'Món Việt'},
    {'label': 'Đồ uống', 'value': 'Đồ uống'},
  ];

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFoods() async {
    setState(() {
      _loading = true;
    });

    try {
      final result = await ApiService.searchFoods(
        search: _searchCtrl.text.trim(),
        category: _selectedCategory,
      );

      if (!mounted) return;

      setState(() {
        _foods = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _foods = [];
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được thư viện thực phẩm: $e')),
      );
    }
  }

  void _selectCategory(String value) {
    setState(() {
      _selectedCategory = value;
    });
    _loadFoods();
  }

  Future<void> _showAddFoodDialog() async {
    final nameCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final carbsCtrl = TextEditingController();
    final fatCtrl = TextEditingController();

    String category = 'Món Việt';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: const Text(
                'Thêm thực phẩm',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    _dialogInput(nameCtrl, 'Tên món'),
                    const SizedBox(height: 10),
                    _dialogInput(
                      calCtrl,
                      'Calo / 100g',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    _dialogInput(
                      proteinCtrl,
                      'Protein',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    _dialogInput(
                      carbsCtrl,
                      'Carbs',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    _dialogInput(
                      fatCtrl,
                      'Fat',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: InputDecoration(
                        labelText: 'Danh mục',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Món Việt',
                          child: Text('Món Việt'),
                        ),
                        DropdownMenuItem(
                          value: 'Tinh bột',
                          child: Text('Tinh bột'),
                        ),
                        DropdownMenuItem(value: 'Thịt', child: Text('Thịt')),
                        DropdownMenuItem(value: 'Rau', child: Text('Rau')),
                        DropdownMenuItem(
                          value: 'Đồ uống',
                          child: Text('Đồ uống'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            category = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty ||
                        calCtrl.text.trim().isEmpty) {
                      return;
                    }

                    try {
                      await ApiService.createFood({
                        'name': nameCtrl.text.trim(),
                        'calories': double.tryParse(calCtrl.text.trim()) ?? 0,
                        'protein':
                            double.tryParse(proteinCtrl.text.trim()) ?? 0,
                        'carbs': double.tryParse(carbsCtrl.text.trim()) ?? 0,
                        'fat': double.tryParse(fatCtrl.text.trim()) ?? 0,
                        'serving_size': 100,
                        'serving_unit': 'g',
                        'category': category,
                      });

                      if (ctx.mounted) {
                        Navigator.pop(ctx, true);
                      }
                    } catch (_) {
                      if (ctx.mounted) {
                        Navigator.pop(ctx, false);
                      }
                    }
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    calCtrl.dispose();
    proteinCtrl.dispose();
    carbsCtrl.dispose();
    fatCtrl.dispose();

    if (result == true) {
      _loadFoods();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã thêm thực phẩm')));
      }
    }
  }

  Widget _dialogInput(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFoodDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadFoods,
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
            children: [
              _topHeader(),
              const SizedBox(height: 16),
              _searchCard(),
              const SizedBox(height: 16),
              _categoryChips(),
              const SizedBox(height: 16),
              _foodLibraryCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Thư viện thực phẩm',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(
            Icons.restaurant_menu,
            color: AppColors.primary,
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _searchCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (_) => _loadFoods(),
        decoration: InputDecoration(
          hintText: 'Tìm món ăn...',
          hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: AppColors.textGrey),
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
    );
  }

  Widget _categoryChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = _categories[index];
          final label = item['label']!;
          final value = item['value']!;
          final selected = _selectedCategory == value;

          return GestureDetector(
            onTap: () => _selectCategory(value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
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
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _foodLibraryCard() {
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
                  'Danh sách thực phẩm',
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
                  'Không có thực phẩm',
                  style: TextStyle(color: AppColors.textGrey),
                ),
              ),
            )
          else
            ..._foods.map((food) {
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
    final category = food['category']?.toString() ?? 'Khác';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(23),
            ),
            child: const Center(
              child: Text('🥗', style: TextStyle(fontSize: 23)),
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
                  '$category · $calories kcal / 100g',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'P $protein · C $carbs · F $fat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textLight),
        ],
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
