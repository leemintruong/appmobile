import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/app_events.dart';
import '../theme/app_colors.dart';
import '../widgets/sk_ui.dart';

class AddMealScreen extends StatefulWidget {
  const AddMealScreen({super.key});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _searchCtrl = TextEditingController();
  final Map<int, Map<String, dynamic>> _selected = {};
  final Map<int, TextEditingController> _amountCtrls = {};
  String _mealType = 'breakfast';
  bool _loading = false;
  bool _saving = false;
  List<dynamic> _foods = [];

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    for (final c in _amountCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadFoods() async {
    setState(() => _loading = true);
    try {
      final foods = await ApiService.searchFoods(search: _searchCtrl.text.trim(), limit: 80);
      if (!mounted) return;
      setState(() => _foods = foods);
    } catch (e) {
      if (mounted) _toast('Không tải được món: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggle(Map<String, dynamic> food) {
    final id = int.tryParse('${food['id']}');
    if (id == null) return;
    setState(() {
      if (_selected.containsKey(id)) {
        _selected.remove(id);
        _amountCtrls.remove(id)?.dispose();
      } else {
        _selected[id] = food;
        _amountCtrls[id] = TextEditingController(text: '${NumFmt.read(food['serving_size'], fallback: NumFmt.read(food['base_amount'], fallback: 100)).toStringAsFixed(0)}');
      }
    });
  }

  num _totalCalories() {
    num total = 0;
    _selected.forEach((id, food) {
      final amount = NumFmt.read(_amountCtrls[id]?.text, fallback: 0);
      final base = NumFmt.read(food['base_amount'], fallback: 100);
      total += NumFmt.read(food['calories']) * amount / (base <= 0 ? 100 : base);
    });
    return total;
  }

  Future<void> _save() async {
    if (_selected.isEmpty) {
      _toast('Chọn ít nhất một món ăn');
      return;
    }
    setState(() => _saving = true);
    try {
      final items = <Map<String, dynamic>>[];
      _selected.forEach((id, food) {
        final amount = NumFmt.read(_amountCtrls[id]?.text, fallback: 0);
        if (amount > 0) {
          items.add({'food_id': id, 'amount': amount, 'amount_unit': food['base_unit'] ?? 'g'});
        }
      });
      final result = await ApiService.addMeal(mealType: _mealType, items: items, date: ApiService.localDateKey());
      if (!mounted) return;
      if (result['success'] == true) {
        AppEvents.notifyDataChanged();
        Navigator.pop(context, true);
      } else {
        _toast(result['message'] ?? 'Không lưu được bữa ăn');
      }
    } catch (e) {
      if (mounted) _toast('Lỗi lưu bữa ăn: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(children: [
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
                const Expanded(child: Text('Thêm bữa ăn', style: TextStyle(color: AppColors.textDark, fontSize: 24, fontWeight: FontWeight.w900))),
                Text('${_totalCalories().toStringAsFixed(0)} kcal', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)),
              ]),
            ),
            _mealTypeBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: TextField(
                controller: _searchCtrl,
                onSubmitted: (_) => _loadFoods(),
                decoration: InputDecoration(
                  hintText: 'Tìm món ăn',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(onPressed: _loadFoods, icon: const Icon(Icons.arrow_forward_rounded)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                      itemCount: _foods.length,
                      itemBuilder: (_, i) => _foodRow(Map<String, dynamic>.from(_foods[i] as Map), i),
                    ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        color: AppColors.background,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
        child: SkPrimaryButton(label: 'Lưu bữa ăn', icon: Icons.save_rounded, onPressed: _save, loading: _saving),
      ),
    );
  }

  Widget _mealTypeBar() {
    final types = {'breakfast': 'Sáng', 'lunch': 'Trưa', 'dinner': 'Tối', 'snack': 'Bữa phụ'};
    return SizedBox(
      height: 46,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        children: types.entries.map((e) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: SkChip(label: e.value, selected: _mealType == e.key, onTap: () => setState(() => _mealType = e.key)),
        )).toList(),
      ),
    );
  }

  Widget _foodRow(Map<String, dynamic> food, int index) {
    final id = int.tryParse('${food['id']}') ?? 0;
    final selected = _selected.containsKey(id);
    return SkFadeSlide(
      delayMs: index * 14,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SkCard(
          padding: const EdgeInsets.all(14),
          radius: 22,
          onTap: () => _toggle(food),
          child: Column(children: [
            Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: selected ? AppColors.primary : AppColors.primarySoft, borderRadius: BorderRadius.circular(16)),
                child: Icon(selected ? Icons.check_rounded : Icons.restaurant_rounded, color: selected ? Colors.white : AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${food['name']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('${NumFmt.whole(food['calories'])} kcal / ${NumFmt.whole(food['base_amount'])}${food['base_unit'] ?? 'g'}', style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
              ])),
              Text('${NumFmt.whole(food['protein'])}g P', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
            ]),
            if (selected) ...[
              const SizedBox(height: 12),
              Row(children: [
                const Text('Lượng ăn', style: TextStyle(color: AppColors.textGrey)),
                const SizedBox(width: 10),
                SizedBox(
                  width: 96,
                  child: TextField(
                    controller: _amountCtrls[id],
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      suffixText: '${food['base_unit'] ?? 'g'}',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                    ),
                  ),
                ),
              ]),
            ],
          ]),
        ),
      ),
    );
  }
}
