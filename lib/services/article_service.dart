// lib/services/article_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';
import '../utils/constants.dart';
import 'auth_service.dart'; // Untuk mendapatkan token JWT

// Helper class untuk membawa data artikel beserta info pagination
class PaginatedArticlesResponse {
  final List<Article> articles;
  final bool hasMore;

  PaginatedArticlesResponse({required this.articles, required this.hasMore});
}

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

  // Mengambil daftar semua artikel dengan pagination
  Future<PaginatedArticlesResponse> fetchArticles({
    int page = 1,
    int limit = 10,
    String? category,
  }) async {
    String url = '$_baseUrl/news?page=$page&limit=$limit';
    if (category != null && category.isNotEmpty) {
      url += '&category=$category';
    }
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> articlesJson = data['data']['articles'];
      final bool hasMore = data['data']['pagination']['hasMore'] ?? false;
      return PaginatedArticlesResponse(
        articles: articlesJson.map((json) => Article.fromJson(json)).toList(),
        hasMore: hasMore,
      );
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to load articles');
    }
  }

  // Mengambil artikel trending dengan pagination
  Future<PaginatedArticlesResponse> fetchTrendingArticles({
    int page = 1,
    int limit = 10,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/news/trending?page=$page&limit=$limit'),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> articlesJson = data['data']['articles'];
      final bool hasMore = data['data']['pagination']['hasMore'] ?? false;
      return PaginatedArticlesResponse(
        articles: articlesJson.map((json) => Article.fromJson(json)).toList(),
        hasMore: hasMore,
      );
    } else {
      final errorData = json.decode(response.body);
      throw Exception(
        errorData['message'] ?? 'Failed to load trending articles',
      );
    }
  }

  // Mengambil artikel yang dibuat oleh pengguna yang sedang login
  Future<PaginatedArticlesResponse> fetchUserArticles({
    int page = 1,
    int limit = 10,
  }) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/news/user/me?page=$page&limit=$limit'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> articlesJson = data['data']['articles'];
      final bool hasMore = data['data']['pagination']['hasMore'] ?? false;
      return PaginatedArticlesResponse(
        articles: articlesJson.map((json) => Article.fromJson(json)).toList(),
        hasMore: hasMore,
      );
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to load user articles');
    }
  }

  // Mengambil artikel yang di-bookmark oleh pengguna
  Future<List<Article>> fetchBookmarkedArticles() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/news/bookmarks/list'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      // API untuk list bookmark mungkin tidak memiliki 'articles' key, sesuaikan jika perlu
      final List<dynamic> articlesJson =
          data['data']['bookmarks'] ?? data['data']['articles'] ?? [];
      return articlesJson.map((json) => Article.fromJson(json)).toList();
    } else {
      final errorData = json.decode(response.body);
      throw Exception(
        errorData['message'] ?? 'Failed to load bookmarked articles',
      );
    }
  }

  // Menyimpan bookmark
  Future<void> saveBookmark(String articleId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/news/$articleId/bookmark'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to save bookmark');
    }
  }

  // Menghapus bookmark
  Future<void> removeBookmark(String articleId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$_baseUrl/news/$articleId/bookmark'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to remove bookmark');
    }
  }

  // --- Metode CRUD yang sudah ada (tidak perlu diubah) ---

  Future<Article> fetchArticleById(String id) async {
    final response = await http.get(Uri.parse('$_baseUrl/news/$id'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body)['data'];
      return Article.fromJson(data['article']);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to load article');
    }
  }

  Future<Article> createArticle(Article article) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/news'),
      headers: headers,
      body: json.encode(article.toCreateJson()),
    );
    if (response.statusCode == 201) {
      final Map<String, dynamic> data = json.decode(response.body)['data'];
      return Article.fromJson(data['article']);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to create article');
    }
  }

  Future<Article> updateArticle(String id, Map<String, dynamic> updates) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$_baseUrl/news/$id'),
      headers: headers,
      body: json.encode(updates),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body)['data'];
      return Article.fromJson(data['article']);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to update article');
    }
  }

  Future<void> deleteArticle(String id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$_baseUrl/news/$id'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to delete article');
    }
  }
}
