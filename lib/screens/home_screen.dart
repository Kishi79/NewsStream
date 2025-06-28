import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:newsstream/utils/app_styles.dart';
import '../models/article.dart';
import '../services/article_service.dart';
import 'article_detail_screen.dart';
import 'article_form_screen.dart';
import 'profile_screen.dart'; // <-- IMPORT BARU

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ArticleService _articleService = ArticleService();

  // State for data and pagination
  List<Article> _allArticles = [];
  List<Article> _myArticles = [];
  List<Article> _trendingArticles = [];
  List<Article> _bookmarkedArticles = [];
  Set<String> _bookmarkedArticleIds = {};

  // State for loading and pagination control
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
      3: ScrollController(),
    };
    _loadInitialData();
  }

  Future<void> _refreshData() async {
    // Reset state before loading
    setState(() {
      _allArticles.clear();
      _myArticles.clear();
      _trendingArticles.clear();
      _bookmarkedArticles.clear();
      _currentPage = {0: 1, 1: 1, 2: 1};
      _hasMore = {0: true, 1: true, 2: true};
    });
    await _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.wait([
        _loadArticles(0, isInitial: true),
        _loadArticles(1, isInitial: true),
        _loadArticles(2, isInitial: true),
        _loadBookmarkedArticles(isInitial: true),
      ]);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadArticles(int tabIndex, {bool isInitial = false}) async {
    if (_isLoadingMore[tabIndex] == true || !_hasMore[tabIndex]!) return;

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

      if (mounted) {
        setState(() {
          List<Article> currentList = _getListForIndex(tabIndex);
          if (isInitial) currentList.clear();
          currentList.addAll(response.articles);
          _hasMore[tabIndex] = response.hasMore;
          if (response.hasMore) {
            _currentPage[tabIndex] = _currentPage[tabIndex]! + 1;
          }
        });
      }
    } catch (e) {
      if (isInitial && mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (!isInitial && mounted) {
        setState(() {
          _isLoadingMore[tabIndex] = false;
        });
      }
    }
  }

  Future<void> _loadBookmarkedArticles({bool isInitial = false}) async {
    final articles = await _articleService.fetchBookmarkedArticles();
    if (mounted) {
      setState(() {
        _bookmarkedArticles = articles;
        _bookmarkedArticleIds = articles.map((a) => a.id).toSet();
      });
    }
  }

  void _onScroll(int tabIndex) {
    final controller = _scrollControllers[tabIndex]!;
    if (controller.position.pixels >=
            controller.position.maxScrollExtent - 300 &&
        _hasMore[tabIndex]! &&
        _isLoadingMore[tabIndex] == false) {
      _loadArticles(tabIndex);
    }
  }

  void _navigateToCreateArticle() async {
    final newArticle = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ArticleFormScreen()));
    if (newArticle != null && newArticle is Article) {
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
          // <-- PERUBAHAN DIMULAI DI SINI
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            tooltip: 'My Profile',
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _navigateToCreateArticle,
            tooltip: 'Create New Article',
          ),
          // Tombol logout telah dihapus dari sini
          // <-- PERUBAHAN BERAKHIR DI SINI
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All Articles'),
            Tab(text: 'My Articles'),
            Tab(text: 'Trending'),
            Tab(text: 'Bookmarks'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(child: Text('Failed to load data: $_errorMessage'))
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildArticleList(0),
                  _buildArticleList(1),
                  _buildArticleList(2),
                  _buildArticleList(3),
                ],
              ),
    );
  }

  Widget _buildArticleList(int tabIndex) {
    final articles = _getListForIndex(tabIndex);
    final isLoadingMore = _isLoadingMore[tabIndex] ?? false;

    if (articles.isEmpty && !isLoadingMore) {
      return RefreshIndicator(
        onRefresh: _refreshData,
        child: Center(
          child: ListView(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.3),
              const Center(
                child: Text('No articles found.', style: AppStyles.bodyText),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        controller: _scrollControllers[tabIndex],
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: articles.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == articles.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final article = articles[index];
          final isBookmarked = _bookmarkedArticleIds.contains(article.id);

          return _ArticleCard(
            article: article,
            isBookmarked: isBookmarked,
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
            onBookmark: () {
              // Optimistic UI update
              setState(() {
                if (isBookmarked) {
                  _bookmarkedArticleIds.remove(article.id);
                  _bookmarkedArticles.removeWhere((a) => a.id == article.id);
                } else {
                  _bookmarkedArticleIds.add(article.id);
                  _bookmarkedArticles.add(article);
                }
              });

              // API call
              if (!isBookmarked) {
                _articleService
                    .saveBookmark(article.id)
                    .catchError(
                      (_) => setState(
                        () => _bookmarkedArticleIds.remove(article.id),
                      ),
                    );
              } else {
                _articleService
                    .removeBookmark(article.id)
                    .catchError(
                      (_) =>
                          setState(() => _bookmarkedArticleIds.add(article.id)),
                    );
              }
            },
          );
        },
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final Article article;
  final bool isBookmarked;
  final VoidCallback onTap;
  final VoidCallback onBookmark;

  const _ArticleCard({
    required this.article,
    required this.isBookmarked,
    required this.onTap,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
                child: CachedNetworkImage(
                  imageUrl: article.imageUrl,
                  placeholder:
                      (context, url) => const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  errorWidget:
                      (context, url, error) => const SizedBox(
                        height: 200,
                        child: Icon(
                          Icons.broken_image,
                          size: 40,
                          color: AppStyles.secondaryTextColor,
                        ),
                      ),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: AppStyles.articleTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.cardSnippet,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Category: ${article.category} | ${article.readTime}',
                              style: AppStyles.metadata,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'By: ${article.author['name'] ?? 'Anonymous'}',
                              style: AppStyles.metadata,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: AppStyles.primaryColor,
                        ),
                        onPressed: onBookmark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
