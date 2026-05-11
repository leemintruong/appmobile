import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Khi chạy emulator Android, dùng 10.0.2.2 thay cho localhost
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // ─── TOKEN ────────────────────────────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── AUTH ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      print('📝 Registering: $email');
      print('📡 API URL: $baseUrl/auth/register');
      
      final res = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout after 10s'),
      );
      
      print('📶 Status: ${res.statusCode}');
      print('📝 Response: ${res.body}');
      
      return jsonDecode(res.body);
    } catch (e) {
      print('❌ Register error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      print('🔐 Logging in: $email');
      print('📡 API URL: $baseUrl/auth/login');

      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Timeout after 10s'),
          );

      print('📶 Status: ${res.statusCode}');
      print('📝 Response: ${res.body}');

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['token'] != null) {
        await saveToken(data['token']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(data['user']));
        print('✅ Login successful');
      }
      return data;
    } catch (e) {
      print('❌ Login error: $e');
      rethrow;
    }
  }

  static Future<void> logout() async => clearToken();

  // ─── PROFILE ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> getProfile() async {
    final res = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: await _headers(),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> data,
  ) async {
    final res = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> setGoal(
    String goalType, {
    double? targetWeight,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/profile/goal'),
      headers: await _headers(),
      body: jsonEncode({
        'goal_type': goalType,
        if (targetWeight != null) 'target_weight': targetWeight,
      }),
    );
    return jsonDecode(res.body);
  }

  // ─── FOODS ────────────────────────────────────────────────
  static Future<List<dynamic>> searchFoods({
    String search = '',
    String category = '',
    int page = 1,
  }) async {
    final params = {
      if (search.isNotEmpty) 'search': search,
      if (category.isNotEmpty) 'category': category,
      'page': '$page',
      'limit': '20',
    };
    final uri = Uri.parse('$baseUrl/foods').replace(queryParameters: params);
    final res = await http.get(uri, headers: await _headers());
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getFoodById(int id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/foods/$id'),
      headers: await _headers(),
    );
    return jsonDecode(res.body);
  }

  // ─── MEALS ────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getMeals({String? date}) async {
    final d = date ?? DateTime.now().toIso8601String().substring(0, 10);
    final res = await http.get(
      Uri.parse('$baseUrl/meals?date=$d'),
      headers: await _headers(),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> addMeal({
    required String mealType,
    required List<Map<String, dynamic>> items,
    String? date,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/meals'),
      headers: await _headers(),
      body: jsonEncode({
        'meal_type': mealType,
        'items': items, // [{ food_id, quantity }]
        if (date != null) 'date': date,
      }),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> deleteMeal(int mealLogId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/meals/$mealLogId'),
      headers: await _headers(),
    );
    return jsonDecode(res.body);
  }

  // ─── WEIGHTS ──────────────────────────────────────────────
  static Future<List<dynamic>> getWeights({String? from, String? to}) async {
    final params = <String, String>{};
    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;
    final uri = Uri.parse('$baseUrl/weights').replace(queryParameters: params);
    final res = await http.get(uri, headers: await _headers());
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> addWeight(
    double weight, {
    String? date,
    String? note,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/weights'),
      headers: await _headers(),
      body: jsonEncode({
        'weight': weight,
        if (date != null) 'date': date,
        if (note != null) 'note': note,
      }),
    );
    return jsonDecode(res.body);
  }

  static Future<void> deleteWeight(int id) async {
    await http.delete(
      Uri.parse('$baseUrl/weights/$id'),
      headers: await _headers(),
    );
  }

  // ─── REPORTS ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> getDailyReport({String? date}) async {
    final d = date ?? DateTime.now().toIso8601String().substring(0, 10);
    final res = await http.get(
      Uri.parse('$baseUrl/reports/daily?date=$d'),
      headers: await _headers(),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getWeeklyReport({String? start}) async {
    final s =
        start ??
        DateTime.now()
            .subtract(const Duration(days: 6))
            .toIso8601String()
            .substring(0, 10);
    final res = await http.get(
      Uri.parse('$baseUrl/reports/weekly?start=$s'),
      headers: await _headers(),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getMonthlyReport({String? month}) async {
    final m = month ?? DateTime.now().toIso8601String().substring(0, 7);
    final res = await http.get(
      Uri.parse('$baseUrl/reports/monthly?month=$m'),
      headers: await _headers(),
    );
    return jsonDecode(res.body);
  }
}
