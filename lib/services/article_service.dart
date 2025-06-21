// lib/services/article_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';
import '../utils/constants.dart';
import 'auth_service.dart'; // Untuk mendapatkan token JWT

class ArticleService {
  final String _baseUrl = Constants.baseUrl;
  final AuthService _authService = AuthService();

  // Helper method untuk mendapatkan header yang dibutuhkan, termasuk Authorization token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getUserToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Mengambil daftar semua artikel atau filter berdasarkan kategori
  // Endpoint: GET /news
  Future<List<Article>> fetchArticles({int page = 1, int limit = 10, String? category}) async {
    String url = '$_baseUrl/news?page=$page&limit=$limit';
    if (category != null && category.isNotEmpty) {
      url += '&category=$category';
    }
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) { // 200 OK
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> articlesJson = data['data']['articles'];
      return articlesJson.map((json) => Article.fromJson(json)).toList();
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to load articles');
    }
  }

  // Mengambil detail artikel berdasarkan ID
  // Endpoint: GET /news/{id}
  Future<Article> fetchArticleById(String id) async {
    final response = await http.get(Uri.parse('$_baseUrl/news/$id'));

    if (response.statusCode == 200) { // 200 OK
      final Map<String, dynamic> data = json.decode(response.body)['data'];
      return Article.fromJson(data['article']);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to load article');
    }
  }

  // Membuat artikel baru
  // Endpoint: POST /news (Protected)
  Future<Article> createArticle(Article article) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/news'),
      headers: headers,
      body: json.encode(article.toCreateJson()), // Menggunakan metode toCreateJson()
    );

    if (response.statusCode == 201) { // 201 Created
      final Map<String, dynamic> data = json.decode(response.body)['data'];
      return Article.fromJson(data['article']);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to create article');
    }
  }

  // Memperbarui artikel yang sudah ada
  // Endpoint: PUT /news/{id} (Protected)
  Future<Article> updateArticle(String id, Map<String, dynamic> updates) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$_baseUrl/news/$id'),
      headers: headers,
      body: json.encode(updates),
    );

    if (response.statusCode == 200) { // 200 OK
      final Map<String, dynamic> data = json.decode(response.body)['data'];
      return Article.fromJson(data['article']);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to update article');
    }
  }

  // Menghapus artikel
  // Endpoint: DELETE /news/{id} (Protected)
  Future<void> deleteArticle(String id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$_baseUrl/news/$id'),
      headers: headers,
    );

    if (response.statusCode != 200) { // Seharusnya 200 OK untuk berhasil menghapus
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to delete article');
    }
  }

  // Mengambil artikel yang dibuat oleh pengguna yang sedang login
  // Endpoint: GET /news/user/me (Protected)
  Future<List<Article>> fetchUserArticles() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$_baseUrl/news/user/me'), headers: headers);

    if (response.statusCode == 200) { // 200 OK
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> articlesJson = data['data']['articles'];
      return articlesJson.map((json) => Article.fromJson(json)).toList();
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to load user articles');
    }
  }
}