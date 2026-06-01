import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/app_events.dart';
import '../theme/app_colors.dart';
import '../widgets/sk_ui.dart';

class ActivityScreen extends StatefulWidget { const ActivityScreen({super.key}); @override State<ActivityScreen> createState() => _ActivityScreenState(); }

class _ActivityScreenState extends State<ActivityScreen> {
  final _nameCtrl = TextEditingController(text: 'Đi bộ nhanh');
  final _minutesCtrl = TextEditingController(text: '30');
  final _calCtrl = TextEditingController(text: '120');
  bool _loading = true; Map<String, dynamic> _data = {};
  @override void initState(){super.initState(); _load();}
  @override void dispose(){_nameCtrl.dispose();_minutesCtrl.dispose();_calCtrl.dispose();super.dispose();}
  Future<void> _load() async { setState(()=>_loading=true); try{final d=await ApiService.getActivities(date: ApiService.localDateKey()); if(mounted)setState(()=>_data=d);}catch(e){if(mounted)_toast('Không tải được vận động: $e');} if(mounted)setState(()=>_loading=false);}
  Future<void> _save() async { final r=await ApiService.addActivity(activityName: _nameCtrl.text.trim(), durationMinutes: int.tryParse(_minutesCtrl.text)??0, caloriesBurned: double.tryParse(_calCtrl.text)??0, date: ApiService.localDateKey()); if(r['success']==true){AppEvents.notifyDataChanged();_load();}else{_toast(r['message']??'Không lưu được vận động');}}
  void _toast(String m)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  @override Widget build(BuildContext context){final logs=_data['activities'] is List?_data['activities'] as List:[]; return Scaffold(backgroundColor:AppColors.background,body:SafeArea(child:ListView(padding:const EdgeInsets.fromLTRB(20,14,20,30),children:[Row(children:[IconButton(onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.arrow_back_rounded)),const Expanded(child:Text('Theo dõi vận động',style:TextStyle(color:AppColors.textDark,fontSize:24,fontWeight:FontWeight.w900)))]),const SizedBox(height:12),SkCard(child:Column(children:[SkTextField(controller:_nameCtrl,label:'Hoạt động',hint:'Đi bộ nhanh'),const SizedBox(height:12),Row(children:[Expanded(child:SkTextField(controller:_minutesCtrl,label:'Phút',hint:'30',keyboardType:TextInputType.number)),const SizedBox(width:12),Expanded(child:SkTextField(controller:_calCtrl,label:'Calo',hint:'120',keyboardType:TextInputType.number))]),const SizedBox(height:16),SkPrimaryButton(label:'Lưu hoạt động',icon:Icons.save_rounded,onPressed:_save)])),const SizedBox(height:16),SkCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Hoạt động hôm nay',style:TextStyle(color:AppColors.textDark,fontWeight:FontWeight.w900,fontSize:18)),const SizedBox(height:10),if(_loading)const Center(child:CircularProgressIndicator(color:AppColors.primary))else if(logs.isEmpty)const Text('Chưa có dữ liệu',style:TextStyle(color:AppColors.textGrey))else ...logs.map((x){final m=Map<String,dynamic>.from(x as Map);return ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.directions_walk_rounded,color:AppColors.primary),title:Text('${m['activity_name']}'),subtitle:Text('${m['duration_minutes']} phút · ${m['calories_burned']} kcal'));})]))])));}
}
