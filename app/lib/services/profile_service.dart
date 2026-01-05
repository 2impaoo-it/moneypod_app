import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:moneypod/models/profile.dart';
import 'package:moneypod/repositories/profile_repository.dart';

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
              headers: {'ngrok-skip-browser-warning': 'true'},
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
    final path = '/profile';
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
    // User specified key 'file'
    final form = FormData.fromMap({'file': mp});

    try {
      // Step 1: Upload image to get URL
      debugPrint('Step 1: Uploading to /upload');
      final uploadResp = await _dio.post(
        '/upload',
        data: form,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          contentType: 'multipart/form-data',
        ),
      );
      debugPrint('Step 1 Success: ${uploadResp.data}');

      if (uploadResp.statusCode == 200 && uploadResp.data != null) {
        final data = uploadResp.data is Map
            ? Map<String, dynamic>.from(uploadResp.data)
            : <String, dynamic>{};
        // Try to find the URL in common fields
        final innerData = (data['data'] is Map) ? data['data'] : data;
        final imageUrl =
            innerData['url'] ??
            innerData['secure_url'] ??
            innerData['file_url'] ??
            innerData['avatar_url'];

        debugPrint('Extracted Image URL: $imageUrl');

        if (imageUrl != null && imageUrl is String) {
          // Step 2: Update profile with the new avatar URL
          debugPrint('Step 2: Updating profile at /profile/avatar with URL');
          try {
            final updateResp = await _dio.put(
              '/profile/avatar',
              data: {'avatar_url': imageUrl},
              options: Options(headers: {'Authorization': 'Bearer $token'}),
            );
            debugPrint('Step 2 Success: ${updateResp.statusCode}');

            if (updateResp.statusCode == 200) {
              return imageUrl;
            }
          } catch (e) {
            if (e is DioException) {
              debugPrint(
                'Step 2 Error: ${e.message} - ${e.response?.statusCode}',
              );
              debugPrint('Step 2 Path: ${e.requestOptions.uri}');
            }
            rethrow;
          }
        }
      }
    } catch (e) {
      if (e is DioException) {
        debugPrint('Upload avatar error: ${e.message}');
        debugPrint('Failed Request URI: ${e.requestOptions.uri}');
        debugPrint('Response Data: ${e.response?.data}');
      } else {
        debugPrint('Upload avatar error: $e');
      }
    }
    return null;
  }

  Future<void> updatePhoneNumber(String token, String phone) async {
    try {
      await _dio.post(
        '/profile/phone',
        data: {'phone': phone},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      if (e is DioException) {
        debugPrint('Update phone error: ${e.message} - ${e.response?.data}');
        final data = e.response?.data;
        if (data is Map && data['error'] != null) {
          throw Exception(data['error']);
        }
      } else {
        debugPrint('Update phone error: $e');
      }
      rethrow;
    }
  }
}
