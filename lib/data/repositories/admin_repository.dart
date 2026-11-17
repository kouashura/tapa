import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../core/utils/logger.dart';

class AdminRepository {
  static const String _baseUrl =
      'https://tapa-budget-server.onrender.com/api/admin';

  Future<Map<String, String>> _headers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Non authentifie');
    final idToken = await user.getIdToken(true);
    return {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final r = await http.get(
        Uri.parse('$_baseUrl/users'),
        headers: await _headers(),
      );
      if (r.statusCode != 200) {
        Logger.error('getUsers: ${r.statusCode} ${r.body}');
        return [];
      }
      final data = jsonDecode(r.body);
      if (data['success'] == true && data['users'] != null) {
        return List<Map<String, dynamic>>.from(data['users']);
      }
      return [];
    } catch (e) {
      Logger.error('getUsers: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      final r = await http.get(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: await _headers(),
      );
      if (r.statusCode != 200) return null;
      return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (e) {
      Logger.error('getUserDetails: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getWithdraws() async {
    try {
      final r = await http.get(
        Uri.parse('$_baseUrl/withdraws'),
        headers: await _headers(),
      );
      if (r.statusCode != 200) {
        Logger.error('getWithdraws: ${r.statusCode} ${r.body}');
        return [];
      }
      final data = jsonDecode(r.body);
      if (data['success'] == true && data['requests'] != null) {
        return List<Map<String, dynamic>>.from(data['requests']);
      }
      return [];
    } catch (e) {
      Logger.error('getWithdraws: $e');
      return [];
    }
  }

  Future<bool> approveWithdraw(String id) async {
    try {
      final r = await http.post(
        Uri.parse('$_baseUrl/withdraw/$id/complete'),
        headers: await _headers(),
        body: jsonEncode({'status': 'success'}),
      );
      return r.statusCode == 200;
    } catch (e) {
      Logger.error('approveWithdraw: $e');
      return false;
    }
  }

  Future<bool> rejectWithdraw(String id) async {
    try {
      final r = await http.post(
        Uri.parse('$_baseUrl/withdraw/$id/complete'),
        headers: await _headers(),
        body: jsonEncode({'status': 'failed'}),
      );
      return r.statusCode == 200;
    } catch (e) {
      Logger.error('rejectWithdraw: $e');
      return false;
    }
  }
}
