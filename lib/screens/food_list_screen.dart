import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/app_events.dart';
import '../theme/app_colors.dart';
import '../widgets/sk_ui.dart';

class FoodListScreen extends StatefulWidget {
  const FoodListScreen({super.key});

  @override
  State<FoodListScreen> createState() => _FoodListScreenState();
}

class _FoodListScreenState extends State<FoodListScreen> {
  final _searchCtrl = TextEditingController();
  bool _loading = true;
  int _lastEventVersion = 0;
  List<dynamic> _foods = [];
  List<dynamic> _categories = [];
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _lastEventVersion = AppEvents.dataVersion.value;
    AppEvents.dataVersion.addListener(_onChanged);
    _loadInitial();
  }

  @override
  void dispose() {
    AppEvents.dataVersion.removeListener(_onChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    if (_lastEventVersion != AppEvents.dataVersion.value) {
      _lastEventVersion = AppEvents.dataVersion.value;
      _loadFoods(silent: true);
    }
  }

  Future<void> _loadInitial() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([ApiService.getFoodCategories(), ApiService.searchFoods(limit: 80)]);
      if (!mounted) return;
      setState(() {
        _categories = results[0];
        _foods = results[1];
      });
    } catch (e) {
      if (mounted) _toast('Không tải được thư viện: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadFoods({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final foods = await ApiService.searchFoods(search: _searchCtrl.text, categoryId: _selectedCategoryId, limit: 100);
      if (!mounted) return;
      setState(() => _foods = foods);
    } catch (e) {
      if (mounted) _toast('Không tải được món: $e');
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadInitial,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
          children: [
            const Text('Thư viện thực phẩm', style: TextStyle(color: AppColors.textDark, fontSize: 26, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text('Tìm kiếm món ăn, nguyên liệu và món AI đã lưu', style: TextStyle(color: AppColors.textGrey)),
            const SizedBox(height: 18),
            _searchBox(),
            const SizedBox(height: 14),
            _categoryChips(),
            const SizedBox(height: 18),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator(color: AppColors.primary)))
            else if (_foods.isEmpty)
              const SkCard(child: Center(child: Padding(padding: EdgeInsets.all(18), child: Text('Chưa có món phù hợp', style: TextStyle(color: AppColors.textGrey)))))
            else
              ...List.generate(_foods.length, (i) => SkFadeSlide(delayMs: i * 18, child: _foodCard(Map<String, dynamic>.from(_foods[i] as Map)))),
          ],
        ),
      ),
    );
  }

  Widget _searchBox() {
    return TextField(
      controller: _searchCtrl,
      onSubmitted: (_) => _loadFoods(),
      decoration: InputDecoration(
        hintText: 'Tìm cơm, gà, phở, món AI...',
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textGrey),
        suffixIcon: IconButton(icon: const Icon(Icons.tune_rounded), onPressed: _loadFoods),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.primary)),
      ),
    );
  }

  Widget _categoryChips() {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          SkChip(label: 'Tất cả', selected: _selectedCategoryId == null, onTap: () { setState(() => _selectedCategoryId = null); _loadFoods(); }),
          const SizedBox(width: 8),
          ..._categories.map((c) {
            final map = Map<String, dynamic>.from(c as Map);
            final id = int.tryParse('${map['id']}');
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SkChip(label: '${map['name']}', selected: _selectedCategoryId == id, onTap: () { setState(() => _selectedCategoryId = id); _loadFoods(); }),
            );
          }),
        ],
      ),
    );
  }

  Widget _foodCard(Map<String, dynamic> f) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SkCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(width: 52, height: 52, decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.restaurant_rounded, color: AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${f['name'] ?? 'Món ăn'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textDark, fontSize: 15, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text('${NumFmt.whole(f['calories'])} kcal · P ${NumFmt.whole(f['protein'])}g · C ${NumFmt.whole(f['carbs'])}g · F ${NumFmt.whole(f['fat'])}g', style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                const SizedBox(height: 3),
                Text('${f['category'] ?? f['brand'] ?? 'Thực phẩm'}', style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
              ]),
            ),
            Icon(f['is_favorite'] == 1 || f['is_favorite'] == true ? Icons.favorite_rounded : Icons.chevron_right_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
