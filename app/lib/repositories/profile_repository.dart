import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/profile.dart';
import '../utils/dio_client.dart';
import '../config/app_config.dart';

class ProfileRepository {
  late final Dio _dio;

  ProfileRepository({Dio? dio}) {
    _dio = dio ?? DioClient.getDio(null);
    if (dio == null) {
      _dio.options.baseUrl = AppConfig.baseUrl;
    }
  }

  Future<Profile?> fetchUserProfile(String token) async {
    try {
      final response = await _dio.get(
        '/profile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final profileData = response.data['data'] ?? response.data;
        return Profile.fromJson(profileData);
      } else {
        debugPrint(
          'ProfileRepo: Failed to load profile: ${response.statusCode}',
        );
        return null;
      }
    } on DioException catch (e) {
      debugPrint('ProfileRepo: DioException fetching profile: $e');
      return null;
    } catch (e) {
      debugPrint('ProfileRepo: Error fetching profile: $e');
      rethrow;
    }
  }
}
