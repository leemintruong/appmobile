import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Android Emulator dùng 10.0.2.2 để gọi localhost của máy tính.
  // Nếu chạy Chrome thì đổi thành: http://localhost:3000/api
  static const String baseUrl = 'http://10.0.2.2:3000/api';

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
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static dynamic _decodeResponse(http.Response res) {
    try {
      final decoded = jsonDecode(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return decoded;
      }

      if (decoded is Map<String, dynamic>) {
        return {'success': false, 'statusCode': res.statusCode, ...decoded};
      }

      return {
        'success': false,
        'statusCode': res.statusCode,
        'message': 'Request thất bại',
        'data': decoded,
      };
    } catch (_) {
      return {
        'success': false,
        'statusCode': res.statusCode,
        'message': res.body.isNotEmpty ? res.body : 'Không đọc được phản hồi',
      };
    }
  }

  static Map<String, dynamic> normalizeObject(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['data'] is Map<String, dynamic>) {
        return data['data'];
      }

      if (data['profile'] is Map<String, dynamic>) {
        return data['profile'];
      }

      if (data['user'] is Map<String, dynamic>) {
        return data['user'];
      }

      return data;
    }

    return {};
  }

  static List<dynamic> normalizeList(dynamic data) {
    if (data is List) return data;

    if (data is Map<String, dynamic>) {
      if (data['data'] is List) return data['data'];
      if (data['foods'] is List) return data['foods'];
      if (data['items'] is List) return data['items'];
      if (data['weights'] is List) return data['weights'];
      if (data['meals'] is List) return data['meals'];
    }

    return [];
  }

  // AUTH

  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    print('REGISTER STATUS: ${res.statusCode}');
    print('REGISTER BODY: ${res.body}');

    final data = _decodeResponse(res);

    if (data is Map<String, dynamic>) {
      return data;
    }

    return {'success': false, 'message': 'Phản hồi đăng ký không hợp lệ'};
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    print('LOGIN STATUS: ${res.statusCode}');
    print('LOGIN BODY: ${res.body}');

    final data = _decodeResponse(res);

    if (data is Map<String, dynamic>) {
      final token = data['token'] ?? data['accessToken'];

      if (res.statusCode == 200 && token != null) {
        await saveToken(token.toString());

        final prefs = await SharedPreferences.getInstance();

        if (data['user'] != null) {
          await prefs.setString('user', jsonEncode(data['user']));
        }
      }

      return data;
    }

    return {'success': false, 'message': 'Phản hồi đăng nhập không hợp lệ'};
  }

  static Future<void> logout() async {
    await clearToken();
  }

  // PROFILE

  static Future<Map<String, dynamic>> getProfile() async {
    final res = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: await _headers(),
    );

    print('GET PROFILE STATUS: ${res.statusCode}');
    print('GET PROFILE BODY: ${res.body}');

    final data = _decodeResponse(res);

    if (data is Map<String, dynamic>) {
      return data;
    }

    return {'success': false, 'message': 'Không lấy được hồ sơ'};
  }

  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> data,
  ) async {
    final res = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: await _headers(),
      body: jsonEncode(data),
    );

    print('UPDATE PROFILE STATUS: ${res.statusCode}');
    print('UPDATE PROFILE BODY: ${res.body}');

    final decoded = _decodeResponse(res);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {'success': false, 'message': 'Không cập nhật được hồ sơ'};
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

    final data = _decodeResponse(res);

    if (data is Map<String, dynamic>) {
      return data;
    }

    return {'success': false, 'message': 'Không cập nhật được mục tiêu'};
  }

  // FOODS

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

    print('GET FOODS STATUS: ${res.statusCode}');
    print('GET FOODS BODY: ${res.body}');

    final data = _decodeResponse(res);

    return normalizeList(data);
  }

  static Future<Map<String, dynamic>> getFoodById(int id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/foods/$id'),
      headers: await _headers(),
    );

    final data = _decodeResponse(res);

    if (data is Map<String, dynamic>) {
      return normalizeObject(data);
    }

    return {'success': false, 'message': 'Không lấy được món ăn'};
  }

  // MEALS

  static Future<Map<String, dynamic>> getMeals({String? date}) async {
    final d = date ?? DateTime.now().toIso8601String().substring(0, 10);

    final res = await http.get(
      Uri.parse('$baseUrl/meals?date=$d'),
      headers: await _headers(),
    );

    print('GET MEALS STATUS: ${res.statusCode}');
    print('GET MEALS BODY: ${res.body}');

    final data = _decodeResponse(res);

    if (data is Map<String, dynamic>) {
      return data;
    }

    return {'success': false, 'message': 'Không lấy được nhật ký bữa ăn'};
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
        'items': items,
        if (date != null) 'date': date,
      }),
    );

    print('ADD MEAL STATUS: ${res.statusCode}');
    print('ADD MEAL BODY: ${res.body}');

    final data = _decodeResponse(res);

    if (data is Map<String, dynamic>) {
      return data;
    }

    return {'success': false, 'message': 'Không thêm được bữa ăn'};
  }

  static Future<Map<String, dynamic>> deleteMeal(int mealLogId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/meals/$mealLogId'),
      headers: await _headers(),
    );

    final data = _decodeResponse(res);

    if (data is Map<String, dynamic>) {
      return data;
    }

    return {'success': false, 'message': 'Không xóa được bữa ăn'};
  }

  // WEIGHTS

  static Future<List<dynamic>> getWeights({String? from, String? to}) async {
    final params = <String, String>{};

    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;

    final uri = Uri.parse('$baseUrl/weights').replace(queryParameters: params);

    final res = await http.get(uri, headers: await _headers());

    print('GET WEIGHTS STATUS: ${res.statusCode}');
    print('GET WEIGHTS BODY: ${res.body}');

    final data = _decodeResponse(res);

    return normalizeList(data);
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

    final data = _decodeResponse(res);

    if (data is Map<String, dynamic>) {
      return data;
    }

    return {'success': false, 'message': 'Không thêm được cân nặng'};
  }

  static Future<Map<String, dynamic>> deleteWeight(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/weights/$id'),
      headers: await _headers(),
    );

    final data = _decodeResponse(res);

    if (data is Map<String, dynamic>) {
      return data;
    }

    return {'success': false, 'message': 'Không xóa được cân nặng'};
  }

  // REPORTS

  static Future<Map<String, dynamic>> getDailyReport({String? date}) async {
    final d = date ?? DateTime.now().toIso8601String().substring(0, 10);

    final res = await http.get(
      Uri.parse('$baseUrl/reports/daily?date=$d'),
      headers: await _headers(),
    );

    print('GET DAILY REPORT STATUS: ${res.statusCode}');
    print('GET DAILY REPORT BODY: ${res.body}');

    final data = _decodeResponse(res);

    if (data is Map<String, dynamic>) {
      return data;
    }

    return {'success': false, 'message': 'Không lấy được báo cáo ngày'};
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

    final data = _decodeResponse(res);

    if (data is Map<String, dynamic>) {
      return data;
    }

    return {'success': false, 'message': 'Không lấy được báo cáo tuần'};
  }

  static Future<Map<String, dynamic>> getMonthlyReport({String? month}) async {
    final m = month ?? DateTime.now().toIso8601String().substring(0, 7);

    final res = await http.get(
      Uri.parse('$baseUrl/reports/monthly?month=$m'),
      headers: await _headers(),
    );

    final data = _decodeResponse(res);

    if (data is Map<String, dynamic>) {
      return data;
    }

    return {'success': false, 'message': 'Không lấy được báo cáo tháng'};
  }
}
