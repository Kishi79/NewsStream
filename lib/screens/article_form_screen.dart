// lib/screens/article_form_screen.dart
import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/article_service.dart';

class ArticleFormScreen extends StatefulWidget {
  final Article? article; // Null jika membuat baru, ada jika mengedit
  const ArticleFormScreen({super.key, this.article});

  @override
  State<ArticleFormScreen> createState() => _ArticleFormScreenState();
}

class _ArticleFormScreenState extends State<ArticleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _readTimeController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagsController =
      TextEditingController(); // Untuk tag

  bool _isTrending = false;
  bool _isLoading = false;
  final ArticleService _articleService = ArticleService();

  @override
  void initState() {
    super.initState();
    if (widget.article != null) {
      _titleController.text = widget.article!.title;
      _categoryController.text = widget.article!.category;
      _readTimeController.text = widget.article!.readTime;
      _imageUrlController.text = widget.article!.imageUrl;
      _contentController.text = widget.article!.content;
      _isTrending = widget.article!.isTrending;
      _tagsController.text = widget.article!.tags.join(
        ', ',
      ); // Join tags for display
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final List<String> tags =
          _tagsController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

      Article resultArticle;
      if (widget.article == null) {
        // Logika untuk membuat artikel baru (POST)
        final newArticle = Article(
          id: '', // ID akan diisi server
          title: _titleController.text,
          category: _categoryController.text,
          readTime: _readTimeController.text,
          imageUrl: _imageUrlController.text,
          content: _contentController.text,
          isTrending: _isTrending,
          tags: tags,
          publishedAt: '', // Akan diisi server
          author: {}, // Akan diisi server
          createdAt: '',
          updatedAt: '',
        );

        resultArticle = await _articleService.createArticle(newArticle);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Artikel berhasil dibuat!')),
        );
      } else {
        // Logika untuk memperbarui artikel (PUT)
        final Map<String, dynamic> updates = {
          'title': _titleController.text,
          'category': _categoryController.text,
          'readTime': _readTimeController.text,
          'imageUrl': _imageUrlController.text,
          'content': _contentController.text,
          'isTrending': _isTrending,
          'tags': tags,
        };
        resultArticle = await _articleService.updateArticle(
          widget.article!.id,
          updates,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Artikel berhasil diperbarui!')),
        );
      }
      if (mounted) {
        // Kembali ke layar sebelumnya (biasanya HomeScreen atau ArticleDetailScreen)
        // dengan membawa artikel yang berhasil dibuat/diperbarui
        Navigator.of(context).pop(resultArticle);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menyimpan artikel: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _readTimeController.dispose();
    _imageUrlController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.article == null ? 'Buat Artikel Baru' : 'Edit Artikel',
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Judul Artikel',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Judul tidak boleh kosong.';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Kategori tidak boleh kosong.';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _readTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Durasi Baca (e.g., 5 menit)',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Durasi baca tidak boleh kosong.';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _imageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'URL Gambar',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'URL gambar tidak boleh kosong.';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _tagsController,
                        decoration: const InputDecoration(
                          labelText:
                              'Tags (pisahkan dengan koma, misal: tech, ai)',
                        ),
                      ),
                      TextFormField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          labelText: 'Konten Artikel',
                        ),
                        maxLines: 10,
                        keyboardType: TextInputType.multiline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Konten artikel tidak boleh kosong.';
                          }
                          return null;
                        },
                      ),
                      Row(
                        children: [
                          const Text('Trending:'),
                          Switch(
                            value: _isTrending,
                            onChanged: (newValue) {
                              setState(() {
                                _isTrending = newValue;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _submitForm,
                        child: Text(
                          widget.article == null
                              ? 'Buat Artikel'
                              : 'Simpan Perubahan',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
