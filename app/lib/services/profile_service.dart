import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:MoneyPod/models/profile.dart';
import 'package:MoneyPod/repositories/profile_repository.dart';

class ProfileService {
  final Dio _dio;
  final ProfileRepository _profileRepository;

  ProfileService([ProfileRepository? repo, Dio? dio])
    : _profileRepository = repo ?? ProfileRepository(),
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl:
                  'https://pseudoeconomical-loise-interpolable.ngrok-free.dev/api/v1',
            ),
          );

  Future<Profile?> getUserProfile(String token) async {
    try {
      return await _profileRepository.fetchUserProfile(token);
    } catch (_) {
      return null;
    }
  }

  Future<Profile?> updateUserProfile(
    String token,
    Map<String, dynamic> updates, {
    String? userId,
  }) async {
    final path = userId != null ? '/users/$userId' : '/profile';
    try {
      final resp = await _dio.put(
        path,
        data: updates,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (resp.statusCode == 200 && resp.data != null) {
        final data = resp.data['data'] ?? resp.data;
        return Profile.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (_) {}
    return null;
  }

  Future<String?> uploadAvatar(
    String token,
    File file, {
    String? userId,
  }) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final mp = await MultipartFile.fromFile(file.path, filename: fileName);
    final form = FormData.fromMap({'avatar': mp});
    final path = userId != null ? '/users/$userId/avatar' : '/profile/avatar';

    try {
      final resp = await _dio.post(
        path,
        data: form,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          contentType: 'multipart/form-data',
        ),
      );
      if (resp.statusCode == 200 && resp.data is Map) {
        final responseData = Map<String, dynamic>.from(resp.data);
        final data = responseData['data'] ?? responseData;
        return data['avatar_url'] as String? ?? data['avatar'] as String?;
      }
    } catch (_) {}
    return null;
  }
}
