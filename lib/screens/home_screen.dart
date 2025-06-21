import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/article.dart';
import '../services/article_service.dart';
import '../services/auth_service.dart';
import 'article_detail_screen.dart';
import 'article_form_screen.dart';
import 'auth_screen.dart'; // Import AuthScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Article>> _allArticlesFuture;
  late Future<List<Article>> _myArticlesFuture;
  late TabController _tabController;

  final ArticleService _articleService = ArticleService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadArticles();
  }

  void _loadArticles() {
    setState(() {
      _allArticlesFuture = _articleService.fetchArticles();
      _myArticlesFuture =
          _articleService.fetchUserArticles(); // Membutuhkan token
    });
  }

  Future<void> _refreshArticles() async {
    _loadArticles();
  }

  void _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    }
  }

  void _navigateToCreateArticle() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ArticleFormScreen()));
    _refreshArticles(); // Refresh after creating a new article
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NewsStream'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToCreateArticle,
            tooltip: 'Buat Artikel Baru',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Semua Artikel'), Tab(text: 'Artikel Saya')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildArticleList(_allArticlesFuture),
          _buildArticleList(_myArticlesFuture),
        ],
      ),
    );
  }

  Widget _buildArticleList(Future<List<Article>> articlesFuture) {
    return FutureBuilder<List<Article>>(
      future: articlesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _refreshArticles,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Tidak ada berita ditemukan.'));
        } else {
          final articles = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refreshArticles,
            child: ListView.builder(
              itemCount: articles.length,
              itemBuilder: (context, index) {
                final article = articles[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  ArticleDetailScreen(article: article),
                        ),
                      );
                      _refreshArticles(); // Refresh list if something changed in detail (e.g., deleted)
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (article.imageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: CachedNetworkImage(
                                imageUrl: article.imageUrl,
                                placeholder:
                                    (context, url) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                errorWidget:
                                    (context, url, error) =>
                                        const Icon(Icons.broken_image),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 200,
                              ),
                            ),
                          const SizedBox(height: 10),
                          Text(
                            article.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            article
                                .content, // Menggunakan content sebagai deskripsi singkat
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Kategori: ${article.category} | ${article.readTime}',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            'Penulis: ${article.author['name'] ?? 'Anonim'}',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }
      },
    );
  }
}
