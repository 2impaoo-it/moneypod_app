import 'dart:io';
import 'package:dio/dio.dart';

import '../services/auth_service.dart';
import '../utils/dio_client.dart';
import '../config/app_config.dart';

/// Repository cho quản lý Quỹ nhóm (Groups)
class GroupRepository {
  final AuthService _authService = AuthService();
  late final Dio _dio;

  GroupRepository() {
    _dio = DioClient.getDio(null);
    _dio.options.baseUrl = AppConfig.baseUrl;
  }

  /// Tạo quỹ nhóm mới
  ///
  /// Parameters:
  /// - [name]: Tên quỹ nhóm (bắt buộc)
  /// - [description]: Mô tả quỹ nhóm
  /// - [targetAmount]: Số tiền mục tiêu
  /// - [deadline]: Ngày kết thúc (format: YYYY-MM-DD)
  /// - [splitEvenly]: Chia đều cho các thành viên hay không
  /// - [members]: Danh sách thành viên [{user_id, target_contribution}]
  ///
  /// Returns: Map chứa thông tin group vừa tạo (bao gồm invite_code)
  Future<Map<String, dynamic>> createGroup({
    required String name,
    String? description,
    double? targetAmount,
    String? deadline,
    List<Map<String, dynamic>>? members,
  }) async {
    try {
      print('🔵 [GroupRepo] Bắt đầu tạo quỹ nhóm: name=$name');

      // Lấy token
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        print('❌ [GroupRepo] Không có token');
        throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
      }

      print('✅ [GroupRepo] Đã lấy token');

      // Tạo request body theo format backend yêu cầu
      final requestBody = <String, dynamic>{'name': name};

      // Thêm các field optional nếu có
      if (description != null && description.isNotEmpty) {
        requestBody['description'] = description;
      }
      if (targetAmount != null && targetAmount > 0) {
        requestBody['target_amount'] = targetAmount;
      }
      if (deadline != null && deadline.isNotEmpty) {
        requestBody['deadline'] = deadline;
      }

      // Thêm members - backend yêu cầu field này (dù có thể rỗng)
      requestBody['members'] = members ?? [];

      print('📦 [GroupRepo] Request body: $requestBody');

      // Gửi POST request
      print('🌐 [GroupRepo] Gửi POST đến: /groups');

      final response = await _dio.post(
        '/groups',
        data: requestBody,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('📡 [GroupRepo] Status code: ${response.statusCode}');
      print('📡 [GroupRepo] Response body: ${response.data}');

      // Kiểm tra status code
      if (response.statusCode != 200 && response.statusCode != 201) {
        print('❌ [GroupRepo] Lỗi từ server: ${response.data['error']}');
        throw Exception(response.data['error'] ?? 'Không thể tạo quỹ nhóm');
      }

      print('✅ [GroupRepo] Tạo quỹ nhóm thành công!');

      // Parse response
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      if (e.error is SocketException) {
        print('❌ [GroupRepo] Lỗi kết nối mạng');
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
        );
      }
      print('❌ [GroupRepo] DioException: $e');
      throw Exception(e.response?.data['error'] ?? 'Lỗi khi tạo quỹ nhóm: $e');
    } catch (e) {
      print('❌ [GroupRepo] Exception: $e');
      rethrow;
    }
  }

  /// Lấy danh sách quỹ nhóm của user
  Future<List<Map<String, dynamic>>> getGroups() async {
    try {
      print('🔵 [GroupRepo] Lấy danh sách quỹ nhóm...');

      // Lấy token
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        print('❌ [GroupRepo] Không có token');
        throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
      }

      print('✅ [GroupRepo] Đã lấy token');

      // Gửi GET request
      print('🌐 [GroupRepo] Gửi GET đến: /groups');

      final response = await _dio.get(
        '/groups',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('📡 [GroupRepo] Status code: ${response.statusCode}');
      print('📡 [GroupRepo] Response body: ${response.data}');

      // Kiểm tra status code
      if (response.statusCode != 200) {
        print('❌ [GroupRepo] Lỗi từ server: ${response.data['error']}');
        throw Exception(
          response.data['error'] ?? 'Không thể lấy danh sách quỹ nhóm',
        );
      }

      // Parse response
      final List<dynamic> groupsJson = response.data['data'] ?? [];

      print('✅ [GroupRepo] Lấy ${groupsJson.length} quỹ nhóm thành công!');
      return groupsJson.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      if (e.error is SocketException) {
        print('❌ [GroupRepo] Lỗi kết nối mạng');
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
        );
      }
      print('❌ [GroupRepo] DioException: $e');
      throw Exception(
        e.response?.data['error'] ?? 'Lỗi khi lấy danh sách quỹ nhóm: $e',
      );
    } catch (e) {
      print('❌ [GroupRepo] Exception: $e');
      rethrow;
    }
  }

  /// Tham gia quỹ nhóm bằng mã mời
  ///
  /// Parameters:
  /// - [code]: Mã mời (invite code)
  Future<void> joinGroup({required String code}) async {
    try {
      print('🔵 [GroupRepo] Tham gia quỹ nhóm với mã: $code');

      // Lấy token
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        print('❌ [GroupRepo] Không có token');
        throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
      }

      print('✅ [GroupRepo] Đã lấy token');

      // Tạo request body
      final requestBody = {'code': code};
      print('📦 [GroupRepo] Request body: $requestBody');

      // Gửi POST request
      print('🌐 [GroupRepo] Gửi POST đến: /groups/join');

      final response = await _dio.post(
        '/groups/join',
        data: requestBody,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('📡 [GroupRepo] Status code: ${response.statusCode}');
      print('📡 [GroupRepo] Response body: ${response.data}');

      // Kiểm tra status code
      if (response.statusCode != 200 && response.statusCode != 201) {
        print('❌ [GroupRepo] Lỗi từ server: ${response.data['error']}');
        throw Exception(
          response.data['error'] ?? 'Không thể tham gia quỹ nhóm',
        );
      }

      print('✅ [GroupRepo] Tham gia quỹ nhóm thành công!');
    } on DioException catch (e) {
      if (e.error is SocketException) {
        print('❌ [GroupRepo] Lỗi kết nối mạng');
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
        );
      }
      print('❌ [GroupRepo] DioException: $e');
      throw Exception(
        e.response?.data['error'] ?? 'Lỗi khi tham gia quỹ nhóm: $e',
      );
    } catch (e) {
      print('❌ [GroupRepo] Exception: $e');
      rethrow;
    }
  }

  /// Thêm chi tiêu nhóm (Expense Splitting)
  /// POST /groups/expenses
  Future<void> addExpense({
    required String groupId,
    required double amount,
    required String description,
    String? payerId, // Nếu null => 'Tôi' (current user)
    String? imageUrl,
    List<Map<String, dynamic>>? splitDetails,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('Chưa đăng nhập');

      final url = '/groups/expenses';
      final body = <String, dynamic>{
        'group_id': groupId,
        'amount': amount,
        'description': description,
        'payer_id': payerId, // Backend xử lý: nếu null/empty -> user đang login
      };

      if (imageUrl != null && imageUrl.isNotEmpty) {
        body['image_url'] = imageUrl;
      }

      if (splitDetails != null && splitDetails.isNotEmpty) {
        body['split_details'] = splitDetails;
      }

      final response = await _dio.post(
        url,
        data: body,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(response.data['error'] ?? 'Lỗi thêm chi tiêu');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Upload và Phân tích hóa đơn (Multi-Image)
  /// POST /scan-receipt
  Future<Map<String, dynamic>> scanReceipts(List<File> files) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('Chưa đăng nhập');

      final formData = FormData();
      for (var file in files) {
        formData.files.add(
          MapEntry('images', await MultipartFile.fromFile(file.path)),
        );
      }

      final response = await _dio.post(
        '/scan-receipt',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'ngrok-skip-browser-warning': 'true',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['data'] ?? {};
      } else {
        throw Exception('Phân tích ảnh thất bại: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Lỗi quét hóa đơn: $e');
    } catch (e) {
      throw Exception('Lỗi quét hóa đơn: $e');
    }
  }

  /// Upload ảnh bill (Single image for storage)
  /// POST /upload
  Future<String> uploadImage(File file) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('Chưa đăng nhập');

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
      });

      final response = await _dio.post(
        '/upload',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'ngrok-skip-browser-warning': 'true',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['url'] ?? '';
      } else {
        throw Exception('Upload ảnh thất bại: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Lỗi upload ảnh: $e');
    } catch (e) {
      throw Exception('Lỗi upload ảnh: $e');
    }
  }

  /// Lấy danh sách nợ của tôi (Tôi nợ ai)
  /// GET /groups/:group_id/my-debts
  Future<List<Map<String, dynamic>>> getMyDebts(String groupId) async {
    try {
      final token = await _authService.getToken();
      final response = await _dio.get(
        '/groups/$groupId/my-debts',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'ngrok-skip-browser-warning': 'true',
          },
        ),
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error getMyDebts: $e');
      return [];
    }
  }

  /// Lấy danh sách ai nợ tôi
  /// GET /groups/:group_id/debts-to-me
  Future<List<Map<String, dynamic>>> getDebtsToMe(String groupId) async {
    try {
      final token = await _authService.getToken();
      final response = await _dio.get(
        '/groups/$groupId/debts-to-me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error getDebtsToMe: $e');
      return [];
    }
  }

  /// Đánh dấu đã trả nợ
  /// PUT /groups/debts/:debt_id/paid
  Future<void> markDebtPaid(String debtId) async {
    try {
      final token = await _authService.getToken();
      final response = await _dio.put(
        '/groups/debts/$debtId/paid',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200) {
        throw Exception(response.data['error'] ?? 'Lỗi cập nhật trạng thái nợ');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Thêm thành viên vào nhóm (Add Member)
  /// POST /groups/:group_id/members
  Future<void> addMember(String groupId, String email) async {
    try {
      final token = await _authService.getToken();
      final response = await _dio.post(
        '/groups/$groupId/members',
        data: {'email': email},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'ngrok-skip-browser-warning': 'true',
          },
        ),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(response.data['error'] ?? 'Lỗi thêm thành viên');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Thêm thành viên bằng số điện thoại
  /// POST /groups/:id/members
  Future<void> addMemberByPhone(String groupId, String phone) async {
    try {
      final token = await _authService.getToken();

      final response = await _dio.post(
        '/groups/$groupId/members',
        data: {'phone': phone},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'ngrok-skip-browser-warning': 'true',
          },
        ),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(response.data['error'] ?? 'Lỗi thêm thành viên');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Xóa thành viên khỏi nhóm (Chỉ trưởng nhóm)
  /// DELETE /groups/:id/members/:user_id
  Future<void> removeMember(String groupId, String memberId) async {
    try {
      final token = await _authService.getToken();

      final response = await _dio.delete(
        '/groups/$groupId/members/$memberId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'ngrok-skip-browser-warning': 'true',
          },
        ),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(response.data['error'] ?? 'Lỗi xóa thành viên');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Lấy chi tiết nhóm (bao gồm thành viên)
  /// GET /groups/:group_id
  Future<Map<String, dynamic>> getGroupDetails(String groupId) async {
    try {
      final token = await _authService.getToken();
      final response = await _dio.get(
        '/groups/$groupId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'ngrok-skip-browser-warning': 'true',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data['data'] ?? {};
      } else {
        // Fallback: Nếu API detail không có, lấy từ list
        final groups = await getGroups();
        return groups.firstWhere(
          (element) => element['id'] == groupId,
          orElse: () => {},
        );
      }
    } catch (e) {
      print('Error getGroupDetails: $e');
      throw Exception('Lỗi khi lấy thông tin nhóm: $e');
    }
  }

  /// Xóa nhóm (Chỉ trưởng nhóm)
  /// DELETE /groups/:id
  Future<void> deleteGroup(String groupId) async {
    try {
      final token = await _authService.getToken();
      final response = await _dio.delete(
        '/groups/$groupId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'ngrok-skip-browser-warning': 'true',
          },
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(response.data['error'] ?? 'Lỗi khi xóa nhóm');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Lấy lịch sử chi tiêu của nhóm
  /// GET /groups/:id/expenses
  Future<List<Map<String, dynamic>>> getGroupExpenses(String groupId) async {
    try {
      final token = await _authService.getToken();
      final response = await _dio.get(
        '/groups/$groupId/expenses',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'ngrok-skip-browser-warning': 'true',
          },
        ),
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      print('Error getGroupExpenses: $e');
      return [];
    }
  }
}
