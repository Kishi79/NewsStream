import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/article.dart';
import '../services/article_service.dart';
import '../services/auth_service.dart';
import 'article_detail_screen.dart';
import 'article_form_screen.dart';
import 'auth_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ArticleService _articleService = ArticleService();
  final AuthService _authService = AuthService();

  // State untuk data dan pagination
  List<Article> _allArticles = [];
  List<Article> _myArticles = [];
  List<Article> _trendingArticles = [];
  List<Article> _bookmarkedArticles = [];
  Set<String> _bookmarkedArticleIds = {};

  // State untuk loading dan pagination control
  bool _isLoading = true;
  Map<int, bool> _isLoadingMore = {0: false, 1: false, 2: false};
  Map<int, bool> _hasMore = {0: true, 1: true, 2: true};
  Map<int, int> _currentPage = {0: 1, 1: 1, 2: 1};
  Map<int, ScrollController> _scrollControllers = {};

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollControllers = {
      0: ScrollController()..addListener(() => _onScroll(0)),
      1: ScrollController()..addListener(() => _onScroll(1)),
      2: ScrollController()..addListener(() => _onScroll(2)),
      3: ScrollController(), // Bookmark tidak pakai pagination
    };
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch initial data for all tabs in parallel
      await Future.wait([
        _loadArticles(0, isInitial: true),
        _loadArticles(1, isInitial: true),
        _loadArticles(2, isInitial: true),
        _loadBookmarkedArticles(isInitial: true),
      ]);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadArticles(int tabIndex, {bool isInitial = false}) async {
    if (_isLoadingMore[tabIndex] == true) return;

    if (!isInitial) {
      setState(() {
        _isLoadingMore[tabIndex] = true;
      });
    }

    try {
      final PaginatedArticlesResponse response;
      switch (tabIndex) {
        case 0:
          response = await _articleService.fetchArticles(
            page: _currentPage[tabIndex]!,
          );
          break;
        case 1:
          response = await _articleService.fetchUserArticles(
            page: _currentPage[tabIndex]!,
          );
          break;
        case 2:
          response = await _articleService.fetchTrendingArticles(
            page: _currentPage[tabIndex]!,
          );
          break;
        default:
          return;
      }

      setState(() {
        List<Article> currentList = _getListForIndex(tabIndex);
        if (isInitial) currentList.clear();
        currentList.addAll(response.articles);
        _hasMore[tabIndex] = response.hasMore;
        if (response.hasMore) {
          _currentPage[tabIndex] = _currentPage[tabIndex]! + 1;
        }
      });
    } catch (e) {
      // Handle error per tab if needed
      if (isInitial) rethrow;
    } finally {
      if (!isInitial) {
        setState(() {
          _isLoadingMore[tabIndex] = false;
        });
      }
    }
  }

  Future<void> _loadBookmarkedArticles({bool isInitial = false}) async {
    final articles = await _articleService.fetchBookmarkedArticles();
    setState(() {
      _bookmarkedArticles = articles;
      _bookmarkedArticleIds = articles.map((a) => a.id).toSet();
    });
  }

  void _onScroll(int tabIndex) {
    final controller = _scrollControllers[tabIndex]!;
    if (controller.position.pixels >=
            controller.position.maxScrollExtent - 200 &&
        _hasMore[tabIndex]!) {
      _loadArticles(tabIndex);
    }
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
    final newArticle = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ArticleFormScreen()));
    if (newArticle != null && newArticle is Article) {
      // Optimistic UI update
      setState(() {
        _allArticles.insert(0, newArticle);
        _myArticles.insert(0, newArticle);
      });
    }
  }

  void _handleDetailScreenResult(dynamic result) {
    if (result == null || result is! Map) return;

    final id = result['id'];
    final res = result['result'];

    if (res == DetailScreenResult.deleted) {
      setState(() {
        _allArticles.removeWhere((a) => a.id == id);
        _myArticles.removeWhere((a) => a.id == id);
        _trendingArticles.removeWhere((a) => a.id == id);
        _bookmarkedArticles.removeWhere((a) => a.id == id);
        _bookmarkedArticleIds.remove(id);
      });
    } else if (res == DetailScreenResult.updated) {
      final Article updatedArticle = result['article'];
      final bool isBookmarked = result['isBookmarked'];

      setState(() {
        _updateArticleInList(_allArticles, updatedArticle);
        _updateArticleInList(_myArticles, updatedArticle);
        _updateArticleInList(_trendingArticles, updatedArticle);
        _updateArticleInList(_bookmarkedArticles, updatedArticle);

        if (isBookmarked) {
          _bookmarkedArticleIds.add(updatedArticle.id);
          // Jika belum ada di daftar bookmark, tambahkan
          if (!_bookmarkedArticles.any((a) => a.id == updatedArticle.id)) {
            _bookmarkedArticles.insert(0, updatedArticle);
          }
        } else {
          _bookmarkedArticleIds.remove(updatedArticle.id);
          _bookmarkedArticles.removeWhere((a) => a.id == updatedArticle.id);
        }
      });
    }
  }

  void _updateArticleInList(List<Article> list, Article article) {
    final index = list.indexWhere((a) => a.id == article.id);
    if (index != -1) {
      list[index] = article;
    }
  }

  List<Article> _getListForIndex(int index) {
    switch (index) {
      case 0:
        return _allArticles;
      case 1:
        return _myArticles;
      case 2:
        return _trendingArticles;
      case 3:
        return _bookmarkedArticles;
      default:
        return [];
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollControllers.forEach((_, controller) => controller.dispose());
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
          isScrollable: true,
          tabs: const [
            Tab(text: 'Semua Artikel'),
            Tab(text: 'Artikel Saya'),
            Tab(text: 'Trending'),
            Tab(text: 'Bookmark'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(child: Text('Gagal memuat data: $_errorMessage'))
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildArticleList(0), // Semua Artikel
                  _buildArticleList(1), // Artikel Saya
                  _buildArticleList(2), // Trending
                  _buildArticleList(3), // Bookmark
                ],
              ),
    );
  }

  Widget _buildArticleList(int tabIndex) {
    final articles = _getListForIndex(tabIndex);
    final isLoadingMore = _isLoadingMore[tabIndex] ?? false;

    if (articles.isEmpty && !isLoadingMore) {
      return RefreshIndicator(
        onRefresh: _loadInitialData,
        child: Center(
          child: ListView(
            // Wrap with ListView for RefreshIndicator
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.3),
              const Text('Tidak ada artikel ditemukan.'),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView.builder(
        controller: _scrollControllers[tabIndex],
        itemCount: articles.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == articles.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final article = articles[index];
          final isBookmarked = _bookmarkedArticleIds.contains(article.id);

          return Card(
            margin: const EdgeInsets.all(8.0),
            child: InkWell(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ArticleDetailScreen(
                          article: article,
                          isBookmarked: isBookmarked,
                        ),
                  ),
                );
                _handleDetailScreenResult(result);
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
                      article.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                        IconButton(
                          icon: Icon(
                            isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                          ),
                          onPressed: () {
                            // Optimistic UI update before calling API
                            setState(() {
                              if (isBookmarked) {
                                _bookmarkedArticleIds.remove(article.id);
                                _bookmarkedArticles.removeWhere(
                                  (a) => a.id == article.id,
                                );
                              } else {
                                _bookmarkedArticleIds.add(article.id);
                                _bookmarkedArticles.add(article);
                              }
                            });
                            // Call API in background
                            if (!isBookmarked) {
                              _articleService
                                  .saveBookmark(article.id)
                                  .catchError((_) {
                                    // Revert UI on error
                                    setState(
                                      () => _bookmarkedArticleIds.remove(
                                        article.id,
                                      ),
                                    );
                                  });
                            } else {
                              _articleService
                                  .removeBookmark(article.id)
                                  .catchError((_) {
                                    // Revert UI on error
                                    setState(
                                      () =>
                                          _bookmarkedArticleIds.add(article.id),
                                    );
                                  });
                            }
                          },
                        ),
                      ],
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
}
