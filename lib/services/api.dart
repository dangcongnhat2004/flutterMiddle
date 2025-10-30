import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class Api {
  static const String base = "http://192.168.1.10:8080";

  static Future<String?> _token() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString('token');
  }

  static Future<Map<String, String>> _headers({
    bool auth = false,
    Map<String, String>? extra,
  }) async {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final t = await _token();
      if (t != null) h['Authorization'] = 'Bearer $t';
    }
    if (extra != null) h.addAll(extra);
    return h;
  }

  static Future<(bool, String?)> login(String email, String password) async {
    final uri = Uri.parse("$base/auth/login");
    final res = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final sp = await SharedPreferences.getInstance();
      await sp.setString('token', data['token']);
      return (true, null);
    }
    return (false, jsonDecode(res.body)['error']?.toString() ?? "Login failed");
  }

  static Future<void> logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('token');
  }

  static Future<List<dynamic>> listUsers() async {
    final uri = Uri.parse("$base/users");
    final res = await http.get(uri, headers: await _headers(auth: true));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception("Failed to load users: ${res.body}");
  }

  static Future<Map<String, dynamic>> createUser({
    required String username,
    required String email,
    required String password,
    File? image,
  }) async {
    final uri = Uri.parse("$base/users");
    final request = http.MultipartRequest('POST', uri);
    final sp = await SharedPreferences.getInstance();
    final t = sp.getString('token');
    if (t != null) request.headers['Authorization'] = 'Bearer $t';
    request.fields['username'] = username;
    request.fields['email'] = email;
    request.fields['password'] = password;
    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
    }
    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 201) {
      return jsonDecode(body);
    }
    throw Exception("Create failed: $body");
  }

  static Future<Map<String, dynamic>> updateUser({
    required String id,
    String? username,
    String? email,
    String? password,
    File? image,
  }) async {
    final uri = Uri.parse("$base/users/$id");
    final request = http.MultipartRequest('PUT', uri);
    final sp = await SharedPreferences.getInstance();
    final t = sp.getString('token');
    if (t != null) request.headers['Authorization'] = 'Bearer $t';
    if (username != null) request.fields['username'] = username;
    if (email != null) request.fields['email'] = email;
    if (password != null) request.fields['password'] = password;
    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
    }
    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 200) {
      return jsonDecode(body);
    }
    throw Exception("Update failed: $body");
  }

  static Future<List<dynamic>> searchUsers(String q) async {
    final uri = Uri.parse("$base/users/search?q=$q");
    final res = await http.get(uri, headers: await _headers(auth: true));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception("Search failed: ${res.body}");
  }

  static Future<void> deleteUser(String id) async {
    final uri = Uri.parse("$base/users/$id");
    final res = await http.delete(uri, headers: await _headers(auth: true));
    if (res.statusCode != 200) throw Exception("Delete failed: ${res.body}");
  }

  static Future<String> chat(String message) async {
    final uri = Uri.parse("$base/chat");
    final res = await http.post(
      uri,
      headers: await _headers(auth: true),
      body: jsonEncode({"message": message}),
    );
    final data = jsonDecode(res.body);
    return data['reply'] ?? "No response";
  }

  static Future<String> exportExcel() async {
    try {
      // Add authorization header since we're accessing user data
      final res = await http.get(
        Uri.parse("$base/export"),
        headers: await _headers(auth: true),
      );

      if (res.statusCode != 200) {
        final error = jsonDecode(res.body)['error'] ?? 'Unknown error';
        throw Exception('Failed to download Excel file: $error');
      }

      // Get the filename from Content-Disposition header or use default
      String filename = 'users.xlsx';
      final disposition = res.headers['content-disposition'];
      if (disposition != null && disposition.contains('filename=')) {
        filename = disposition.split('filename=')[1].replaceAll('"', '');
      }

      // Save to Downloads folder on Android/iOS
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = File(
        "${dir.path}/${filename.replaceAll('.xlsx', '')}_$timestamp.xlsx",
      );
      await file.writeAsBytes(res.bodyBytes);

      // First try to open the file
      final result = await OpenFilex.open(
        file.path,
        type:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        uti: 'com.microsoft.excel.xlsx',
      );

      // If opening fails or returns error, share the file instead
      if (result.type != ResultType.done ||
          result.message.toLowerCase().contains('error')) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Danh sách người dùng',
          text: 'Xuất danh sách từ Admin Panel',
        );
      }

      return file.path;
    } catch (e) {
      throw Exception('Lỗi khi xuất file Excel: $e');
    }
  }
}
