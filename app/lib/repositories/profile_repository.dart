import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/profile.dart';

class ProfileRepository {
  static const String _baseUrl =
      'https://pseudoeconomical-loise-interpolable.ngrok-free.dev/api/v1';

  Future<Profile?> fetchUserProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final profileData = data['data'] ?? data;
        return Profile.fromJson(profileData);
      } else {
        print('ProfileRepo: Failed to load profile: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('ProfileRepo: Error fetching profile: $e');
      throw e;
    }
  }
}
