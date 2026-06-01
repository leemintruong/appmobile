import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/app_events.dart';
import '../theme/app_colors.dart';
import '../widgets/sk_ui.dart';

class AiScanScreen extends StatefulWidget {
  final bool showBackButton;
  const AiScanScreen({super.key, this.showBackButton = true});

  @override
  State<AiScanScreen> createState() => _AiScanScreenState();
}

class _AiScanScreenState extends State<AiScanScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _scanning = false;
  bool _saving = false;
  String _mealType = 'breakfast';
  Map<String, dynamic>? _result;
  List<dynamic> _items = [];
  int? _scanResultId;

  num _n(dynamic v) => NumFmt.read(v);

  Future<void> _scan(ImageSource source) async {
    final image = await _picker.pickImage(source: source, imageQuality: 45, maxWidth: 700, maxHeight: 700);
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
        _scanResultId = int.tryParse('${data['scan_result_id']}');
        _items = data['items'] is List ? data['items'] as List : [];
      });
    } catch (e) {
      if (mounted) _toast('Lỗi scan: $e');
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _addItemToLibrary(Map<String, dynamic> item) async {
    final scanId = _scanResultId;
    final itemId = int.tryParse('${item['id'] ?? item['item_id']}');
    if (scanId == null || itemId == null) {
      _toast('Không xác định được món AI');
      return;
    }

    setState(() => _saving = true);
    try {
      final result = await ApiService.addAiItemToFoodLibrary(scanResultId: scanId, itemId: itemId);
      if (!mounted) return;
      if (result['success'] == true) {
        final foodId = result['food_id'] ?? result['id'];
        setState(() {
          _items = _items.map((x) {
            final m = Map<String, dynamic>.from(x as Map);
            if (int.tryParse('${m['id'] ?? m['item_id']}') == itemId) m['matched_food_id'] = foodId;
            return m;
          }).toList();
        });
        AppEvents.notifyDataChanged();
        _toast('Đã thêm vào thư viện thực phẩm');
      } else {
        _toast(result['message'] ?? 'Không thêm được món');
      }
    } catch (e) {
      if (mounted) _toast('Lỗi thêm thư viện: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirm() async {
    final id = _scanResultId;
    if (id == null) {
      _toast('Chưa có kết quả AI để lưu');
      return;
    }
    setState(() => _saving = true);
    try {
      final result = await ApiService.confirmScanResult(id, mealType: _mealType, date: ApiService.localDateKey());
      if (!mounted) return;
      if (result['success'] == true) {
        AppEvents.notifyDataChanged();
        _toast('Đã lưu bữa ăn AI');
        if (widget.showBackButton) {
          Navigator.pop(context, true);
        } else {
          setState(() {
            _result = null;
            _items = [];
            _scanResultId = null;
          });
        }
      } else {
        _toast(result['message'] ?? 'Không lưu được bữa ăn AI');
      }
    } catch (e) {
      if (mounted) _toast('Lỗi lưu AI: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
        children: [
          _header(),
          const SizedBox(height: 18),
          SkFadeSlide(child: _scanHero()),
          const SizedBox(height: 16),
          SkFadeSlide(delayMs: 80, child: _mealTypeBar()),
          if (_result != null) ...[
            const SizedBox(height: 16),
            SkFadeSlide(delayMs: 100, child: _resultCard()),
            const SizedBox(height: 16),
            SkFadeSlide(delayMs: 120, child: _itemsCard()),
            const SizedBox(height: 16),
            SkPrimaryButton(label: 'Xác nhận và lưu bữa ăn', icon: Icons.check_circle_rounded, onPressed: _confirm, loading: _saving),
          ],
        ],
      ),
    );
  }

  Widget _header() {
    return Row(children: [
      if (widget.showBackButton) ...[
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
        const SizedBox(width: 6),
      ],
      const Expanded(child: Text('AI quét món ăn', style: TextStyle(color: AppColors.textDark, fontSize: 26, fontWeight: FontWeight.w900))),
      Container(width: 42, height: 42, decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle), child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary)),
    ]);
  }

  Widget _scanHero() {
    return SkCard(
      child: Column(children: [
        Container(
          height: 190,
          decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(26)),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _scanning
                  ? const CircularProgressIndicator(color: AppColors.primary)
                  : const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 76),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text('AI nhận diện món ăn', style: TextStyle(color: AppColors.textDark, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('Chụp hoặc chọn ảnh món ăn để Gemini ước tính calo và macro.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textGrey, height: 1.4)),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: SkPrimaryButton(label: 'Chụp ảnh', icon: Icons.camera_alt_rounded, onPressed: () => _scan(ImageSource.camera), loading: _scanning)),
          const SizedBox(width: 10),
          SizedBox(width: 58, height: 56, child: ElevatedButton(onPressed: _scanning ? null : () => _scan(ImageSource.gallery), style: ElevatedButton.styleFrom(elevation: 0, backgroundColor: AppColors.primarySoft, foregroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))), child: const Icon(Icons.photo_library_rounded))),
        ]),
      ]),
    );
  }

  Widget _mealTypeBar() {
    final types = {'breakfast': 'Sáng', 'lunch': 'Trưa', 'dinner': 'Tối', 'snack': 'Bữa phụ'};
    return SkCard(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: types.entries.map((e) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: SkChip(label: e.value, selected: _mealType == e.key, onTap: () => setState(() => _mealType = e.key)),
        )).toList()),
      ),
    );
  }

  Widget _resultCard() {
    return SkCard(
      color: AppColors.primary,
      child: Row(children: [
        const Icon(Icons.bolt_rounded, color: Colors.white, size: 42),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Tổng ước tính', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
          Text('${NumFmt.whole(_result?['estimated_calories'])} kcal', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
          Text('P ${NumFmt.whole(_result?['estimated_protein'])}g · C ${NumFmt.whole(_result?['estimated_carbs'])}g · F ${NumFmt.whole(_result?['estimated_fat'])}g', style: const TextStyle(color: Colors.white70)),
        ])),
      ]),
    );
  }

  Widget _itemsCard() {
    return SkCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Món AI nhận diện', style: TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        ..._items.map((item) {
          final m = Map<String, dynamic>.from(item as Map);
          final name = m['detected_food_name'] ?? m['name'] ?? 'Món ăn';
          final hasFood = m['matched_food_id'] != null && '${m['matched_food_id']}' != 'null';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(18)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(hasFood ? Icons.verified_rounded : Icons.restaurant_rounded, color: hasFood ? AppColors.primary : AppColors.textGrey),
                const SizedBox(width: 8),
                Expanded(child: Text('$name', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w900))),
                Text('${NumFmt.whole(m['estimated_calories'] ?? m['calories'])} kcal', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)),
              ]),
              const SizedBox(height: 6),
              Text('${NumFmt.whole(m['estimated_amount'] ?? m['amount'])}${m['estimated_unit'] ?? m['unit'] ?? ''} · P ${NumFmt.whole(m['estimated_protein'])}g · C ${NumFmt.whole(m['estimated_carbs'])}g · F ${NumFmt.whole(m['estimated_fat'])}g', style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
              const SizedBox(height: 8),
              hasFood
                  ? const Text('Đã liên kết với thư viện thực phẩm', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 12))
                  : SkOutlineButton(label: 'Thêm vào thư viện', icon: Icons.add_rounded, onPressed: _saving ? null : () => _addItemToLibrary(m)),
            ]),
          );
        }),
      ]),
    );
  }
}
