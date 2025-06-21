// lib/models/article.dart
class Article {
  final String id;
  final String title;
  final String category;
  final String publishedAt;
  final String readTime;
  final String imageUrl;
  final bool isTrending;
  final List<String> tags;
  final String content;
  final Map<String, dynamic> author; // Bisa diubah jadi Author model jika kompleks
  final String createdAt;
  final String updatedAt;

  Article({
    required this.id,
    required this.title,
    required this.category,
    required this.publishedAt,
    required this.readTime,
    required this.imageUrl,
    required this.isTrending,
    required this.tags,
    required this.content,
    required this.author,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] ?? '', // ID bisa kosong saat pembuatan, akan diisi server
      title: json['title'] ?? 'No Title',
      category: json['category'] ?? 'General',
      publishedAt: json['publishedAt'] ?? '',
      readTime: json['readTime'] ?? '',
      imageUrl: json['imageUrl'] ?? 'https://via.placeholder.com/200', // Gambar placeholder
      isTrending: json['isTrending'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      content: json['content'] ?? 'No Content',
      author: json['author'] ?? {}, // Author akan diisi server
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  // Metode ini digunakan saat membuat artikel baru (POST /news)
  // Hanya sertakan field yang dibutuhkan oleh API untuk input.
  // publishedAt, author, createdAt, updatedAt, dan id akan digenerate server.
  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      'category': category,
      'readTime': readTime,
      'imageUrl': imageUrl,
      'isTrending': isTrending,
      'tags': tags,
      'content': content,
    };
  }
}