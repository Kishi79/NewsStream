import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/article.dart';
import '../services/article_service.dart';
import 'article_form_screen.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Article article;
  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final ArticleService _articleService = ArticleService();
  late Article _currentArticle;

  @override
  void initState() {
    super.initState();
    _currentArticle = widget.article;
  }

  Future<void> _confirmDelete() async {
    final bool? confirm = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: const Text(
              'Apakah Anda yakin ingin menghapus artikel ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm == true) {
      _deleteArticle();
    }
  }

  void _deleteArticle() async {
    try {
      await _articleService.deleteArticle(_currentArticle.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Artikel berhasil dihapus.')),
        );
        Navigator.of(
          context,
        ).pop(true); // Kembali ke Home dan beri tahu bahwa ada perubahan
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menghapus artikel: ${e.toString().replaceFirst('Exception: ', '')}',
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
      setState(() {
        _currentArticle = updatedArticle;
      });
      // Optionally, pass back to home screen to refresh list
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentArticle.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditArticle,
            tooltip: 'Edit Artikel',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDelete,
            tooltip: 'Hapus Artikel',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_currentArticle.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: CachedNetworkImage(
                  imageUrl: _currentArticle.imageUrl,
                  placeholder:
                      (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                  errorWidget:
                      (context, url, error) => const Icon(Icons.broken_image),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 250,
                ),
              ),
            const SizedBox(height: 15),
            Text(
              _currentArticle.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Kategori: ${_currentArticle.category} | Durasi Baca: ${_currentArticle.readTime}',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey[700],
              ),
            ),
            Text(
              'Penulis: ${_currentArticle.author['name'] ?? 'Anonim'} | ${DateTime.parse(_currentArticle.publishedAt).toLocal().toString().split(' ')[0]}',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 15),
            Text(
              _currentArticle.content,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 20),
            // Jika ada URL asli berita (misalnya dari NewsAPI), bisa ditambahkan tombol untuk membuka
            // if (article.url.isNotEmpty)
            //   Center(
            //     child: ElevatedButton.icon(
            //       onPressed: () async {
            //         final Uri url = Uri.parse(article.url);
            //         if (await canLaunchUrl(url)) {
            //           await launchUrl(url);
            //         } else {
            //           ScaffoldMessenger.of(context).showSnackBar(
            //             SnackBar(content: Text('Tidak bisa membuka URL: ${article.url}')),
            //           );
            //         }
            //       },
            //       icon: const Icon(Icons.open_in_new),
            //       label: const Text('Baca Berita Lengkap'),
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }
}
