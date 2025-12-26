import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/group.dart';

class GroupService {
  // Sử dụng cùng base URL với AuthService
  // Khi kết nối qua USB: dùng 10.0.2.2 (cho Android emulator) hoặc localhost (cho USB với adb reverse)
  // Khi kết nối qua WiFi: dùng IP máy tính (ví dụ: 192.168.1.100)
  static const String baseUrl = 'http://192.168.1.172:8080/api/v1';

  final storage = const FlutterSecureStorage();

  // Lấy token để gửi kèm trong các request cần xác thực
  Future<String?> _getToken() async {
    return await storage.read(key: 'auth_token');
  }

  // Tạo headers với token xác thực
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // 1. Tạo nhóm mới
  Future<Map<String, dynamic>> createGroup({required String name}) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/groups'),
        headers: headers,
        body: jsonEncode({'name': name}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final group = data['data'] != null ? Group.fromJson(data['data']) : null;
        return {
          'success': true,
          'message': data['message'] ?? 'Tạo nhóm thành công',
          'group': group,
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Tạo nhóm thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  // 2. Lấy danh sách nhóm của tôi
  Future<Map<String, dynamic>> getMyGroups() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/groups'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<Group> groups = [];
        if (data['data'] != null) {
          for (var item in data['data']) {
            groups.add(Group.fromJson(item));
          }
        }
        return {
          'success': true,
          'groups': groups,
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Lấy danh sách nhóm thất bại',
          'groups': <Group>[],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
        'groups': <Group>[],
      };
    }
  }

  // 3. Tham gia nhóm bằng mã code
  Future<Map<String, dynamic>> joinGroup({required String code}) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/groups/join'),
        headers: headers,
        body: jsonEncode({'code': code}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Tham gia nhóm thành công!',
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Tham gia nhóm thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  // 4. Thêm hóa đơn và chia tiền trong nhóm
  Future<Map<String, dynamic>> addExpense({
    required int groupId,
    required double amount,
    required String note,
    required List<int> memberIds,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/groups/expenses'),  // Đổi từ expense → expenses
        headers: headers,
        body: jsonEncode({
          'group_id': groupId,
          'amount': amount,
          'note': note,
          'member_ids': memberIds,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Đã thêm hóa đơn và chia tiền thành công!',
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Thêm hóa đơn thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  // 5. Lấy chi tiết nhóm (bao gồm danh sách thành viên)
  Future<Map<String, dynamic>> getGroupDetails({required int groupId}) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/groups/$groupId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final group = data['data'] != null ? Group.fromJson(data['data']) : null;
        return {
          'success': true,
          'group': group,
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Lấy thông tin nhóm thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  // 6. Lấy danh sách giao dịch/hóa đơn của nhóm
  Future<Map<String, dynamic>> getGroupExpenses({required int groupId}) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/groups/$groupId/expenses'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<GroupExpense> expenses = [];
        if (data['data'] != null) {
          for (var item in data['data']) {
            expenses.add(GroupExpense.fromJson(item));
          }
        }
        return {
          'success': true,
          'expenses': expenses,
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Lấy danh sách giao dịch thất bại',
          'expenses': <GroupExpense>[],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
        'expenses': <GroupExpense>[],
      };
    }
  }

  // 7. Lấy danh sách thành viên của nhóm
  Future<Map<String, dynamic>> getGroupMembers({required int groupId}) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/groups/$groupId/members'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<GroupMember> members = [];
        if (data['data'] != null) {
          for (var item in data['data']) {
            members.add(GroupMember.fromJson(item));
          }
        }
        return {
          'success': true,
          'members': members,
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Lấy danh sách thành viên thất bại',
          'members': <GroupMember>[],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
        'members': <GroupMember>[],
      };
    }
  }

  // 8. Rời khỏi nhóm
  Future<Map<String, dynamic>> leaveGroup({required int groupId}) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/groups/$groupId/leave'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Rời khỏi nhóm thành công',
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Rời khỏi nhóm thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  // 9. Xóa thành viên khỏi nhóm (chỉ admin)
  Future<Map<String, dynamic>> removeMember({
    required int groupId,
    required int userId,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/groups/$groupId/members/$userId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Xóa thành viên thành công',
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Xóa thành viên thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  // 10. Cập nhật quyền của thành viên (chỉ admin)
  Future<Map<String, dynamic>> updateMemberRole({
    required int groupId,
    required int userId,
    required String role, // 'admin' or 'member'
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/groups/$groupId/members/$userId/role'),
        headers: headers,
        body: jsonEncode({'role': role}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Cập nhật quyền thành công',
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Cập nhật quyền thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }
}
