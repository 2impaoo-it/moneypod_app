import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

/// Repository cho quản lý Quỹ nhóm (Groups)
class GroupRepository {
  final AuthService _authService = AuthService();

  // URL server backend
  static const String _baseUrl =
      'https://pseudoeconomical-loise-interpolable.ngrok-free.dev/api/v1';

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
      final url = '$_baseUrl/groups';
      print('🌐 [GroupRepo] Gửi POST đến: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: json.encode(requestBody),
      );

      print('📡 [GroupRepo] Status code: ${response.statusCode}');
      print('📡 [GroupRepo] Response body: ${response.body}');

      // Kiểm tra status code
      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = json.decode(response.body);
        print('❌ [GroupRepo] Lỗi từ server: ${errorData['error']}');
        throw Exception(errorData['error'] ?? 'Không thể tạo quỹ nhóm');
      }

      print('✅ [GroupRepo] Tạo quỹ nhóm thành công!');

      // Parse response
      final responseData = json.decode(response.body);
      return responseData['data'] ?? responseData;
    } on SocketException {
      print('❌ [GroupRepo] Lỗi kết nối mạng');
      throw Exception(
        'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
      );
    } catch (e) {
      print('❌ [GroupRepo] Exception: $e');
      if (e.toString().contains('Exception')) {
        rethrow;
      }
      throw Exception('Lỗi khi tạo quỹ nhóm: $e');
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
      final url = '$_baseUrl/groups';
      print('🌐 [GroupRepo] Gửi GET đến: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      print('📡 [GroupRepo] Status code: ${response.statusCode}');
      print('📡 [GroupRepo] Response body: ${response.body}');

      // Kiểm tra status code
      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        print('❌ [GroupRepo] Lỗi từ server: ${errorData['error']}');
        throw Exception(
          errorData['error'] ?? 'Không thể lấy danh sách quỹ nhóm',
        );
      }

      // Parse response
      final responseData = json.decode(response.body);
      final List<dynamic> groupsJson = responseData['data'] ?? [];

      print('✅ [GroupRepo] Lấy ${groupsJson.length} quỹ nhóm thành công!');
      return groupsJson.cast<Map<String, dynamic>>();
    } on SocketException {
      print('❌ [GroupRepo] Lỗi kết nối mạng');
      throw Exception(
        'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
      );
    } catch (e) {
      print('❌ [GroupRepo] Exception: $e');
      if (e.toString().contains('Exception')) {
        rethrow;
      }
      throw Exception('Lỗi khi lấy danh sách quỹ nhóm: $e');
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
      final url = '$_baseUrl/groups/join';
      print('🌐 [GroupRepo] Gửi POST đến: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: json.encode(requestBody),
      );

      print('📡 [GroupRepo] Status code: ${response.statusCode}');
      print('📡 [GroupRepo] Response body: ${response.body}');

      // Kiểm tra status code
      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = json.decode(response.body);
        print('❌ [GroupRepo] Lỗi từ server: ${errorData['error']}');
        throw Exception(errorData['error'] ?? 'Không thể tham gia quỹ nhóm');
      }

      print('✅ [GroupRepo] Tham gia quỹ nhóm thành công!');
    } on SocketException {
      print('❌ [GroupRepo] Lỗi kết nối mạng');
      throw Exception(
        'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
      );
    } catch (e) {
      print('❌ [GroupRepo] Exception: $e');
      if (e.toString().contains('Exception')) {
        rethrow;
      }
      throw Exception('Lỗi khi tham gia quỹ nhóm: $e');
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

      final url = '$_baseUrl/groups/expenses';
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

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: json.encode(body),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Lỗi thêm chi tiêu');
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

      final url = '$_baseUrl/scan-receipt';
      final request = http.MultipartRequest('POST', Uri.parse(url));

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['ngrok-skip-browser-warning'] = 'true';

      // Attach multiple files with key "images"
      for (var file in files) {
        request.files.add(
          await http.MultipartFile.fromPath('images', file.path),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(responseBody);
        return data['data'] ?? {};
      } else {
        throw Exception('Phân tích ảnh thất bại: ${response.statusCode}');
      }
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

      final url = '$_baseUrl/upload';
      final request = http.MultipartRequest('POST', Uri.parse(url));

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['ngrok-skip-browser-warning'] = 'true';
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(responseBody);
        return data['url'] ?? '';
      } else {
        throw Exception('Upload ảnh thất bại: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi upload ảnh: $e');
    }
  }

  /// Lấy danh sách nợ của tôi (Tôi nợ ai)
  /// GET /groups/:group_id/my-debts
  Future<List<Map<String, dynamic>>> getMyDebts(String groupId) async {
    try {
      final token = await _authService.getToken();
      final url = '$_baseUrl/groups/$groupId/my-debts';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
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
      final url = '$_baseUrl/groups/$groupId/debts-to-me';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
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
      final url = '$_baseUrl/groups/debts/$debtId/paid';

      final response = await http.put(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Lỗi cập nhật trạng thái nợ');
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
      final url = '$_baseUrl/groups/$groupId/members';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: json.encode({'email': email}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Lỗi thêm thành viên');
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
      final url = '$_baseUrl/groups/$groupId/members';

      // Format phone logic if needed (backend might expect +84)
      // Assuming phone passed here is already formatted or raw is fine if backend handles it.
      // Current backend `FindByPhone` looks for exact match.

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: json.encode({'phone': phone}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Lỗi thêm thành viên');
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
      final url = '$_baseUrl/groups/$groupId/members/$memberId';

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Lỗi xóa thành viên');
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
      final url = '$_baseUrl/groups/$groupId';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? {};
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
      final url = '$_baseUrl/groups/$groupId';

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Lỗi khi xóa nhóm');
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
      final url = '$_baseUrl/groups/$groupId/expenses';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      print('Error getGroupExpenses: $e');
      return [];
    }
  }
}
