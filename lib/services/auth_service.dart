import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../utils/constants.dart';

class AuthService {
  final String _baseUrl = Constants.baseUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  Future<void> _deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  Future<User> register({
    required String email,
    required String password,
    required String name,
    String? title,
    String? avatar,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        'name': name,
        'title': title,
        'avatar': avatar,
      }),
    );

    if (response.statusCode == 201) {
      // 201 Created for successful registration
      final Map<String, dynamic> data = json.decode(response.body)['data'];
      await _saveToken(data['token']);
      return User.fromJson(data['user']);
    } else {
      throw Exception(
        json.decode(response.body)['message'] ?? 'Failed to register',
      );
    }
  }

  Future<User> login({required String email, required String password}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      // 200 OK for successful login
      final Map<String, dynamic> data = json.decode(response.body)['data'];
      await _saveToken(data['token']);
      return User.fromJson(data['user']);
    } else {
      throw Exception(
        json.decode(response.body)['message'] ?? 'Failed to login',
      );
    }
  }

  Future<void> logout() async {
    await _deleteToken();
  }

  Future<bool> isLoggedIn() async {
    final token = await _getToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> getUserToken() async {
    return await _getToken();
  }
}
