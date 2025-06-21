import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:newsstream/utils/app_styles.dart';
import '../models/article.dart';
import '../services/article_service.dart';
import 'article_form_screen.dart';

enum DetailScreenResult { updated, deleted }

class ArticleDetailScreen extends StatefulWidget {
  final Article article;
  final bool isBookmarked;

  const ArticleDetailScreen({
    super.key,
    required this.article,
    required this.isBookmarked,
  });

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final ArticleService _articleService = ArticleService();
  late Article _currentArticle;
  late bool _isBookmarked;
  bool _isProcessingBookmark = false;

  @override
  void initState() {
    super.initState();
    _currentArticle = widget.article;
    _isBookmarked = widget.isBookmarked;
  }

  void _popWithResult(Map<String, dynamic> result) {
    if (mounted) {
      Navigator.of(context).pop(result);
    }
  }

  void _toggleBookmark() async {
    if (_isProcessingBookmark) return;

    setState(() => _isProcessingBookmark = true);

    try {
      if (_isBookmarked) {
        await _articleService.removeBookmark(_currentArticle.id);
      } else {
        await _articleService.saveBookmark(_currentArticle.id);
      }
      setState(() => _isBookmarked = !_isBookmarked);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
          ),
        );
      }
    } finally {
      setState(() => _isProcessingBookmark = false);
    }
  }

  Future<void> _confirmDelete() async {
    final bool? confirm = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: const Text(
              'Are you sure you want to delete this article?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) _deleteArticle();
  }

  void _deleteArticle() async {
    try {
      await _articleService.deleteArticle(_currentArticle.id);
      _popWithResult({
        'result': DetailScreenResult.deleted,
        'id': _currentArticle.id,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
          ),
        );
      }
    }
  }

  void _navigateToEditArticle() async {
    final updatedArticle = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ArticleFormScreen(article: _currentArticle),
      ),
    );

    if (updatedArticle != null && updatedArticle is Article) {
      setState(() => _currentArticle = updatedArticle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _popWithResult({
          'result': DetailScreenResult.updated,
          'id': _currentArticle.id,
          'article': _currentArticle,
          'isBookmarked': _isBookmarked,
        });
        return true;
      },
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 250.0,
              pinned: true,
              stretch: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  _currentArticle.title,
                  style: const TextStyle(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                background: CachedNetworkImage(
                  imageUrl: _currentArticle.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget:
                      (context, url, error) =>
                          const Icon(Icons.broken_image, color: Colors.white),
                  placeholder: (context, url) => Container(color: Colors.grey),
                ),
              ),
              actions: [
                IconButton(
                  icon:
                      _isProcessingBookmark
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Icon(
                            _isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                          ),
                  onPressed: _toggleBookmark,
                  tooltip: 'Bookmark Article',
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: _navigateToEditArticle,
                  tooltip: 'Edit Article',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _confirmDelete,
                  tooltip: 'Delete Article',
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_currentArticle.title, style: AppStyles.h1),
                    const SizedBox(height: 12),
                    Text(
                      'By: ${_currentArticle.author['name'] ?? 'Anonymous'}',
                      style: AppStyles.metadata.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Category: ${_currentArticle.category} | Read Time: ${_currentArticle.readTime}',
                      style: AppStyles.metadata,
                    ),
                    const SizedBox(height: 4),
                    if (_currentArticle.publishedAt.isNotEmpty)
                      Text(
                        'Published: ${DateTime.parse(_currentArticle.publishedAt).toLocal().toString().split(' ')[0]}',
                        style: AppStyles.metadata,
                      ),
                    const Divider(height: 30, thickness: 1),
                    Text(_currentArticle.content, style: AppStyles.bodyText),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
