import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Android Emulator: http://10.0.2.2:3000/api
  // Chrome/Windows Desktop: http://localhost:3000/api
  static const String baseUrl = 'http://localhost:3000/api';

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
      if (res.statusCode >= 200 && res.statusCode < 300) return decoded;
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
      for (final key in ['data', 'profile', 'user', 'report', 'result', 'goal']) {
        if (data[key] is Map<String, dynamic>) return data[key];
      }
      return data;
    }
    return {};
  }

  static List<dynamic> normalizeList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in [
        'data',
        'foods',
        'categories',
        'items',
        'weights',
        'meals',
        'days',
        'logs',
        'activities',
        'water',
      ]) {
        if (data[key] is List) return data[key];
      }
    }
    return [];
  }

  static Map<String, dynamic> _asMap(dynamic data, String fallbackMessage) {
    if (data is Map<String, dynamic>) return data;
    return {'success': false, 'message': fallbackMessage};
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
    return _asMap(_decodeResponse(res), 'Phản hồi đăng ký không hợp lệ');
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = _asMap(_decodeResponse(res), 'Phản hồi đăng nhập không hợp lệ');

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

  static Future<void> logout() async => clearToken();

  static Future<Map<String, dynamic>> me() async {
    final res = await http.get(Uri.parse('$baseUrl/auth/me'), headers: await _headers());
    return _asMap(_decodeResponse(res), 'Không lấy được tài khoản');
  }

  // PROFILE / GOAL
  static Future<Map<String, dynamic>> getProfile() async {
    final res = await http.get(Uri.parse('$baseUrl/profile'), headers: await _headers());
    return _asMap(_decodeResponse(res), 'Không lấy được hồ sơ');
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    // Hỗ trợ cả schema cũ và schema V2.
    if (payload['height'] != null && payload['height_cm'] == null) {
      payload['height_cm'] = payload['height'];
    }
    if (payload['weight'] != null && payload['current_weight_kg'] == null) {
      payload['current_weight_kg'] = payload['weight'];
    }

    final res = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    return _asMap(_decodeResponse(res), 'Không cập nhật được hồ sơ');
  }

  static Future<Map<String, dynamic>> setGoal(
    String goalType, {
    double? targetWeight,
  }) async {
    final body = <String, dynamic>{'goal_type': goalType};
    if (targetWeight != null) {
      body['target_weight'] = targetWeight;
      body['target_weight_kg'] = targetWeight;
    }

    final res = await http.post(
      Uri.parse('$baseUrl/profile/goal'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _asMap(_decodeResponse(res), 'Không cập nhật được mục tiêu');
  }

  // FOODS
  static Future<List<dynamic>> getFoodCategories() async {
    final res = await http.get(Uri.parse('$baseUrl/foods/categories'), headers: await _headers());
    return normalizeList(_decodeResponse(res));
  }

  static Future<List<dynamic>> searchFoods({
    String search = '',
    String category = '',
    int? categoryId,
    int page = 1,
    int limit = 50,
  }) async {
    final params = <String, String>{
      if (search.trim().isNotEmpty) 'search': search.trim(),
      if (category.trim().isNotEmpty) 'category': category.trim(),
      if (categoryId != null) 'category_id': '$categoryId',
      'page': '$page',
      'limit': '$limit',
    };
    final uri = Uri.parse('$baseUrl/foods').replace(queryParameters: params);
    final res = await http.get(uri, headers: await _headers());
    return normalizeList(_decodeResponse(res));
  }

  static Future<Map<String, dynamic>> getFoodById(int id) async {
    final res = await http.get(Uri.parse('$baseUrl/foods/$id'), headers: await _headers());
    return normalizeObject(_decodeResponse(res));
  }

  static Future<Map<String, dynamic>> createFood(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/foods'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _asMap(_decodeResponse(res), 'Không thêm được thực phẩm');
  }

  static Future<Map<String, dynamic>> addFavoriteFood(int foodId) async {
    final res = await http.post(Uri.parse('$baseUrl/foods/$foodId/favorite'), headers: await _headers());
    return _asMap(_decodeResponse(res), 'Không lưu được món yêu thích');
  }

  static Future<Map<String, dynamic>> removeFavoriteFood(int foodId) async {
    final res = await http.delete(Uri.parse('$baseUrl/foods/$foodId/favorite'), headers: await _headers());
    return _asMap(_decodeResponse(res), 'Không xóa được món yêu thích');
  }

  // MEALS
  static Future<Map<String, dynamic>> getMeals({String? date}) async {
    final d = date ?? DateTime.now().toIso8601String().substring(0, 10);
    final uri = Uri.parse('$baseUrl/meals').replace(queryParameters: {'date': d});
    final res = await http.get(uri, headers: await _headers());
    return _asMap(_decodeResponse(res), 'Không lấy được nhật ký bữa ăn');
  }

  static Future<Map<String, dynamic>> addMeal({
    required String mealType,
    required List<Map<String, dynamic>> items,
    String? date,
    bool replace = false,
  }) async {
    final body = <String, dynamic>{
      'meal_type': mealType,
      'items': items,
      'replace': replace,
    };
    if (date != null) body['date'] = date;

    final res = await http.post(
      Uri.parse('$baseUrl/meals'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _asMap(_decodeResponse(res), 'Không thêm được bữa ăn');
  }

  static Future<Map<String, dynamic>> deleteMeal(int mealLogId) async {
    final res = await http.delete(Uri.parse('$baseUrl/meals/$mealLogId'), headers: await _headers());
    return _asMap(_decodeResponse(res), 'Không xóa được bữa ăn');
  }

  static Future<Map<String, dynamic>> deleteMealItem(int itemId) async {
    final res = await http.delete(Uri.parse('$baseUrl/meals/items/$itemId'), headers: await _headers());
    return _asMap(_decodeResponse(res), 'Không xóa được món ăn');
  }

  // REPORTS
  static Future<Map<String, dynamic>> getDailyReport({String? date}) async {
    final d = date ?? DateTime.now().toIso8601String().substring(0, 10);
    final uri = Uri.parse('$baseUrl/reports/daily').replace(queryParameters: {'date': d});
    final res = await http.get(uri, headers: await _headers());
    return _asMap(_decodeResponse(res), 'Không lấy được báo cáo ngày');
  }

  static Future<Map<String, dynamic>> getWeeklyReport({String? start, String? end}) async {
    final s = start ?? DateTime.now().subtract(const Duration(days: 6)).toIso8601String().substring(0, 10);
    final params = <String, String>{'start': s};
    if (end != null) params['end'] = end;
    final uri = Uri.parse('$baseUrl/reports/weekly').replace(queryParameters: params);
    final res = await http.get(uri, headers: await _headers());
    return _asMap(_decodeResponse(res), 'Không lấy được báo cáo tuần');
  }

  static Future<Map<String, dynamic>> getMonthlyReport({String? month}) async {
    final m = month ?? DateTime.now().toIso8601String().substring(0, 7);
    final uri = Uri.parse('$baseUrl/reports/monthly').replace(queryParameters: {'month': m});
    final res = await http.get(uri, headers: await _headers());
    return _asMap(_decodeResponse(res), 'Không lấy được báo cáo tháng');
  }

  // WEIGHTS
  static Future<List<dynamic>> getWeights({String? from, String? to}) async {
    final params = <String, String>{};
    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;
    final uri = Uri.parse('$baseUrl/weights').replace(queryParameters: params);
    final res = await http.get(uri, headers: await _headers());
    return normalizeList(_decodeResponse(res));
  }

  static Future<Map<String, dynamic>> addWeight(double weight, {String? date, String? note}) async {
    final body = <String, dynamic>{'weight': weight, 'weight_kg': weight};
    if (date != null) body['date'] = date;
    if (note != null) body['note'] = note;
    final res = await http.post(
      Uri.parse('$baseUrl/weights'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _asMap(_decodeResponse(res), 'Không thêm được cân nặng');
  }

  static Future<Map<String, dynamic>> deleteWeight(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/weights/$id'), headers: await _headers());
    return _asMap(_decodeResponse(res), 'Không xóa được cân nặng');
  }

  // WATER
  static Future<Map<String, dynamic>> getWater({String? date}) async {
    final d = date ?? DateTime.now().toIso8601String().substring(0, 10);
    final uri = Uri.parse('$baseUrl/water').replace(queryParameters: {'date': d});
    final res = await http.get(uri, headers: await _headers());
    return _asMap(_decodeResponse(res), 'Không lấy được nước uống');
  }

  static Future<Map<String, dynamic>> addWater(int amountMl, {String? date}) async {
    final body = <String, dynamic>{'amount_ml': amountMl};
    if (date != null) body['date'] = date;
    final res = await http.post(
      Uri.parse('$baseUrl/water'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _asMap(_decodeResponse(res), 'Không lưu được nước uống');
  }

  // ACTIVITIES
  static Future<Map<String, dynamic>> getActivities({String? date}) async {
    final d = date ?? DateTime.now().toIso8601String().substring(0, 10);
    final uri = Uri.parse('$baseUrl/activities').replace(queryParameters: {'date': d});
    final res = await http.get(uri, headers: await _headers());
    return _asMap(_decodeResponse(res), 'Không lấy được hoạt động');
  }

  static Future<Map<String, dynamic>> addActivity({
    required String activityName,
    required int durationMinutes,
    double caloriesBurned = 0,
    String? date,
  }) async {
    final body = <String, dynamic>{
      'activity_name': activityName,
      'duration_minutes': durationMinutes,
      'calories_burned': caloriesBurned,
    };
    if (date != null) body['date'] = date;

    final res = await http.post(
      Uri.parse('$baseUrl/activities'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _asMap(_decodeResponse(res), 'Không lưu được hoạt động');
  }

  // AI FOOD SCANNER MOCK
  static Future<Map<String, dynamic>> scanMeal({String? imageUrl}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/ai/scan-meal'),
      headers: await _headers(),
      body: jsonEncode({'image_url': imageUrl ?? '/uploads/meals/mock-food.jpg'}),
    );
    return _asMap(_decodeResponse(res), 'Không quét được món ăn');
  }

  static Future<Map<String, dynamic>> getScanResult(int id) async {
    final res = await http.get(Uri.parse('$baseUrl/ai/scan-results/$id'), headers: await _headers());
    return _asMap(_decodeResponse(res), 'Không lấy được kết quả AI');
  }

  static Future<Map<String, dynamic>> confirmScanResult(
    int id, {
    String mealType = 'breakfast',
    String? date,
  }) async {
    final body = <String, dynamic>{'meal_type': mealType};
    if (date != null) body['date'] = date;
    final res = await http.post(
      Uri.parse('$baseUrl/ai/scan-results/$id/confirm'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _asMap(_decodeResponse(res), 'Không lưu được bữa ăn AI');
  }
}
