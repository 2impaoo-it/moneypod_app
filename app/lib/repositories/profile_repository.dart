import 'package:dio/dio.dart';
import '../models/profile.dart';
import '../utils/dio_client.dart';
import '../config/app_config.dart';

class ProfileRepository {
  late final Dio _dio;

  ProfileRepository() {
    _dio = DioClient.getDio(null);
    _dio.options.baseUrl = AppConfig.baseUrl;
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
        print('ProfileRepo: Failed to load profile: ${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      print('ProfileRepo: DioException fetching profile: $e');
      return null;
    } catch (e) {
      print('ProfileRepo: Error fetching profile: $e');
      rethrow;
    }
  }
}
