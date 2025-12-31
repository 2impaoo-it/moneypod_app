import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../models/bill_scan_result.dart';
import '../services/auth_service.dart';
import '../utils/dio_client.dart';

class BillScanRepository {
  final ImagePicker _imagePicker = ImagePicker();
  final AuthService _authService = AuthService();
  late final Dio _dio;

  // URL server backend - thay đổi theo môi trường của bạn
  static const String _baseUrl =
      'https://pseudoeconomical-loise-interpolable.ngrok-free.dev/api/v1';

  BillScanRepository() {
    _dio = DioClient.getDio(null);
    _dio.options.baseUrl = _baseUrl;
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
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/scan-receipt'),
      );

      // Thêm Authorization header với Bearer token
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['ngrok-skip-browser-warning'] = 'true';

      // Thêm file ảnh vào request
      final stream = http.ByteStream(imageFile.openRead());
      final length = await imageFile.length();
      final multipartFile = http.MultipartFile(
        'image',
        stream,
        length,
        filename: 'bill_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      request.files.add(multipartFile);

      // Gửi request lên server
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Kiểm tra status code
      if (response.statusCode != 200) {
        throw Exception(
          'Server trả về lỗi: ${response.statusCode} - ${response.body}',
        );
      }

      // Parse JSON từ response
      final jsonData = json.decode(response.body) as Map<String, dynamic>;

      // Kiểm tra nếu có error từ server
      if (jsonData.containsKey('error')) {
        throw Exception('Lỗi từ server: ${jsonData['error']}');
      }

      // Lấy data từ response
      final data = jsonData['data'] ?? jsonData;

      // Chuyển đổi thành BillScanResult
      return BillScanResult.fromJson(data);
    } on SocketException {
      throw Exception(
        'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
      );
    } catch (e) {
      if (e.toString().contains('Exception')) {
        rethrow;
      }
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
        'note': note ?? '',
        'type': 'expense', // Mặc định là chi tiêu
      };

      // Gửi POST request
      final response = await _dio.post(
        '/transactions',
        data: requestBody,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

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
