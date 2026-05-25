import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/app_events.dart';

class FoodListScreen extends StatefulWidget {
  const FoodListScreen({super.key});

  @override
  State<FoodListScreen> createState() => _FoodListScreenState();
}

class _FoodListScreenState extends State<FoodListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _loading = true;
  List<dynamic> _foods = [];
  List<dynamic> _categories = [];
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getFoodCategories(),
        ApiService.searchFoods(limit: 100),
      ]);
      if (!mounted) return;
      setState(() {
        _categories = results[0];
        _foods = results[1];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được thư viện thực phẩm: $e')),
      );
    }
  }

  Future<void> _loadFoods() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.searchFoods(
        search: _searchCtrl.text.trim(),
        categoryId: _selectedCategoryId,
        limit: 100,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không tải được thực phẩm: $e')));
    }
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

  void _selectCategory(int? id) {
    setState(() => _selectedCategoryId = id);
    _loadFoods();
  }

  Future<void> _toggleFavorite(Map<String, dynamic> food) async {
    final id = int.tryParse('${food['id']}');
    if (id == null) return;

    final isFav = food['is_favorite'] == 1 || food['is_favorite'] == true;
    final result = isFav
        ? await ApiService.removeFavoriteFood(id)
        : await ApiService.addFavoriteFood(id);

    if (!mounted) return;

    if (result['success'] == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Không cập nhật được yêu thích'),
        ),
      );
      return;
    }

    AppEvents.notifyDataChanged();
    _loadFoods();
  }

  Future<void> _showAddFoodDialog() async {
    final nameCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    final proteinCtrl = TextEditingController(text: '0');
    final carbsCtrl = TextEditingController(text: '0');
    final fatCtrl = TextEditingController(text: '0');
    final baseAmountCtrl = TextEditingController(text: '100');
    final baseUnitCtrl = TextEditingController(text: 'g');

    int? categoryId = _selectedCategoryId;

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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dialogInput(nameCtrl, 'Tên món'),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int?>(
                      initialValue: categoryId,
                      decoration: _dialogDecoration('Danh mục'),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Không chọn'),
                        ),
                        ..._categories.map((c) {
                          final map = Map<String, dynamic>.from(c);
                          return DropdownMenuItem<int?>(
                            value: int.tryParse('${map['id']}'),
                            child: Text(_str(map['name'])),
                          );
                        }),
                      ],
                      onChanged: (v) => setDialogState(() => categoryId = v),
                    ),
                    const SizedBox(height: 10),
                    _dialogInput(
                      calCtrl,
                      'Calo theo đơn vị gốc',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _dialogInput(
                            baseAmountCtrl,
                            'Số lượng gốc',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: _dialogInput(baseUnitCtrl, 'Đơn vị')),
                      ],
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
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) return;

    final name = nameCtrl.text.trim();
    final calories = double.tryParse(calCtrl.text.trim());
    final baseAmount = double.tryParse(baseAmountCtrl.text.trim()) ?? 100;
    final baseUnit = baseUnitCtrl.text.trim().isEmpty
        ? 'g'
        : baseUnitCtrl.text.trim();

    if (name.isEmpty || calories == null || calories < 0 || baseAmount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tên món, calo hoặc đơn vị gốc không hợp lệ'),
        ),
      );
      return;
    }

    final createResult = await ApiService.createFood({
      'name': name,
      'category_id': categoryId,
      'calories': calories,
      'protein': double.tryParse(proteinCtrl.text.trim()) ?? 0,
      'carbs': double.tryParse(carbsCtrl.text.trim()) ?? 0,
      'fat': double.tryParse(fatCtrl.text.trim()) ?? 0,
      'base_amount': baseAmount,
      'base_unit': baseUnit,
      'serving_size': baseAmount,
      'serving_unit': baseUnit,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(createResult['message'] ?? 'Đã thêm món ăn')),
    );

    if (createResult['success'] != false) {
      AppEvents.notifyDataChanged();
      _loadFoods();
    }
  }

  InputDecoration _dialogDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }

  Widget _dialogInput(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _dialogDecoration(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddFoodDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm món'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadInitial,
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
            children: [
              _topHeader(),
              const SizedBox(height: 16),
              _searchBox(),
              const SizedBox(height: 14),
              _categoryChips(),
              const SizedBox(height: 16),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_foods.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Chưa có món ăn phù hợp',
                      style: TextStyle(color: AppColors.textGrey),
                    ),
                  ),
                )
              else
                ..._foods.map(
                  (food) => _foodTile(Map<String, dynamic>.from(food)),
                ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thư viện thực phẩm',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Dữ liệu có nguồn và đơn vị rõ ràng',
                style: TextStyle(color: AppColors.textGrey, fontSize: 13),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _loadInitial,
          icon: const Icon(Icons.refresh, color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _searchBox() {
    return TextField(
      controller: _searchCtrl,
      onSubmitted: (_) => _loadFoods(),
      decoration: InputDecoration(
        hintText: 'Tìm cơm, gà, phở, trứng...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            _searchCtrl.clear();
            _loadFoods();
          },
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  Widget _categoryChips() {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip('Tất cả', null),
          ..._categories.map((c) {
            final map = Map<String, dynamic>.from(c);
            return _chip(_str(map['name']), int.tryParse('${map['id']}'));
          }),
        ],
      ),
    );
  }

  Widget _chip(String label, int? id) {
    final selected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        label: Text(label),
        selectedColor: AppColors.primarySoft,
        labelStyle: TextStyle(
          color: selected ? AppColors.primaryDark : AppColors.textGrey,
          fontWeight: FontWeight.w700,
        ),
        onSelected: (_) => _selectCategory(id),
      ),
    );
  }

  Widget _foodTile(Map<String, dynamic> food) {
    final name = _str(food['name'], fallback: 'Món ăn');
    final kcal = _num(food['calories']);
    final baseAmount = _num(
      food['base_amount'],
      fallback: _num(food['serving_size'], fallback: 100),
    );
    final baseUnit = _str(
      food['base_unit'],
      fallback: _str(food['serving_unit'], fallback: 'g'),
    );
    final category = _str(food['category'], fallback: 'Khác');
    final source = _str(food['source_name']);
    final verified = food['is_verified'] == 1 || food['is_verified'] == true;
    final isFav = food['is_favorite'] == 1 || food['is_favorite'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.primarySoft,
            child: Icon(Icons.restaurant_menu, color: AppColors.primary),
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
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$category · ${kcal.toStringAsFixed(0)} kcal / ${baseAmount.toStringAsFixed(0)}$baseUnit',
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      verified ? Icons.verified : Icons.info_outline,
                      size: 14,
                      color: verified ? AppColors.primary : AppColors.textGrey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        source.isNotEmpty
                            ? source
                            : (verified
                                  ? 'Dữ liệu đã kiểm chứng'
                                  : 'Dữ liệu người dùng'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: verified
                              ? AppColors.primaryDark
                              : AppColors.textGrey,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _toggleFavorite(food),
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? AppColors.danger : AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}
