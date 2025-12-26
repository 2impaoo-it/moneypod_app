import 'dart:convert';

import 'package:MoneyPod/models/profile.dart';
import 'package:http/http.dart' as http;

class ProfileRepository {
  final String apiUrl = 'http://192.168.1.172:8080/api/v1';

  Future<Profile?> fetchUserProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        final data = jsonResponse['data'] as Map<String, dynamic>;
        return Profile.fromJson(data);
      } else {
        print('Lỗi khi lấy thông tin hồ sơ: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Lỗi kết nối: $e');
      return null;
    }
  }

  Future<Profile?> updateUserProfile(
    String token,
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/profile/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updates),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        final data = jsonResponse['data'] as Map<String, dynamic>;
        return Profile.fromJson(data);
      } else {
        print('Lỗi khi cập nhật hồ sơ: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Lỗi kết nối: $e');
      return null;
    }
  }
}
