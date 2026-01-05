import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import '../models/bill_scan_result.dart';
import '../services/auth_service.dart';
import '../utils/dio_client.dart';
import '../config/app_config.dart';

class BillScanRepository {
  final ImagePicker _imagePicker;
  final AuthService _authService;
  late final Dio _dio;

  BillScanRepository({
    ImagePicker? imagePicker,
    AuthService? authService,
    Dio? dio,
  }) : _imagePicker = imagePicker ?? ImagePicker(),
       _authService = authService ?? AuthService() {
    _dio = dio ?? DioClient.getDio(null);
    if (dio == null) {
      _dio.options.baseUrl = AppConfig.baseUrl;
    }
  }

  /// Kiểm tra và yêu cầu quyền camera
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Lấy danh sách camera có sẵn
  Future<List<CameraDescription>> getAvailableCameras() async {
    try {
      return await availableCameras();
    } catch (e) {
      throw Exception('Không thể truy cập camera: $e');
    }
  }

  /// Chụp ảnh từ camera
  Future<File> takePictureWithCamera() async {
    final hasPermission = await requestCameraPermission();
    if (!hasPermission) {
      throw Exception('Không có quyền truy cập camera');
    }

    final XFile? photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 85,
    );

    if (photo == null) {
      throw Exception('Không có ảnh được chụp');
    }

    return File(photo.path);
  }

  /// Chọn ảnh từ thư viện
  Future<File> pickImageFromGallery() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) {
      throw Exception('Không có ảnh được chọn');
    }

    return File(image.path);
  }

  /// Quét bill bằng cách gửi ảnh lên server
  Future<BillScanResult> scanBill(File imageFile) async {
    try {
      // Lấy token từ secure storage
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
      }

      // Tạo multipart request
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'bill_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      // Gửi request lên server
      final response = await _dio.post(
        '/scan-receipt',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'ngrok-skip-browser-warning': 'true',
          },
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );

      // Kiểm tra status code
      if (response.statusCode != 200) {
        throw Exception(
          'Server trả về lỗi: ${response.statusCode} - ${response.data}',
        );
      }

      // Lấy data từ response
      final data = response.data['data'] ?? response.data;

      // Chuyển đổi thành BillScanResult
      return BillScanResult.fromJson(data);
    } on DioException catch (e) {
      if (e.error is SocketException) {
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
        );
      }
      throw Exception(e.response?.data['error'] ?? 'Lỗi khi quét bill: $e');
    } catch (e) {
      throw Exception('Lỗi khi quét bill: $e');
    }
  }

  /// Quét bill từ camera (kết hợp chụp + phân tích)
  Future<BillScanResult> scanBillFromCamera() async {
    final imageFile = await takePictureWithCamera();
    return await scanBill(imageFile);
  }

  /// Quét bill từ thư viện ảnh
  Future<BillScanResult> scanBillFromGallery() async {
    final imageFile = await pickImageFromGallery();
    return await scanBill(imageFile);
  }

  /// Lưu transaction sau khi user đã sửa thông tin
  Future<void> saveTransaction({
    required String merchant,
    required double amount,
    required DateTime date,
    required String category,
    required String walletId,
    String? note,
  }) async {
    try {
      // Lấy token từ secure storage
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
      }

      // Tạo request body
      final requestBody = {
        'merchant': merchant,
        'amount': amount,
        'date': date.toIso8601String(),
        'category': category,
        'wallet_id': walletId,
        'note': note ?? '',
        'type': 'expense', // Mặc định là chi tiêu
      };

      // Gửi POST request
      debugPrint('Saving transaction to ${AppConfig.baseUrl}/transactions');
      final response = await _dio.post(
        '/transactions',
        data: requestBody,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      debugPrint('Save transaction response: ${response.statusCode}');

      // Kiểm tra status code
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Lỗi từ server: ${response.data['error'] ?? 'Unknown error'}',
        );
      }

      // Thành công
    } on DioException catch (e) {
      if (e.error is SocketException) {
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
        );
      }
      throw Exception(e.response?.data['error'] ?? 'Lỗi khi lưu giao dịch: $e');
    } catch (e) {
      rethrow;
    }
  }
}
