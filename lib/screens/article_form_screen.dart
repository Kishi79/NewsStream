import 'package:flutter/material.dart';
import 'package:newsstream/utils/app_styles.dart';
import '../models/article.dart';
import '../services/article_service.dart';

class ArticleFormScreen extends StatefulWidget {
  final Article? article;
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
  final TextEditingController _tagsController = TextEditingController();

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
      _tagsController.text = widget.article!.tags.join(', ');
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final List<String> tags =
          _tagsController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

      Article resultArticle;
      if (widget.article == null) {
        final newArticle = Article(
          id: '',
          title: _titleController.text,
          category: _categoryController.text,
          readTime: _readTimeController.text,
          imageUrl: _imageUrlController.text,
          content: _contentController.text,
          isTrending: _isTrending,
          tags: tags,
          publishedAt: '',
          author: {},
          createdAt: '',
          updatedAt: '',
        );

        resultArticle = await _articleService.createArticle(newArticle);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Article created successfully!')),
        );
      } else {
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
          const SnackBar(content: Text('Article updated successfully!')),
        );
      }
      if (mounted) {
        Navigator.of(context).pop(resultArticle);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
          widget.article == null ? 'Create New Article' : 'Edit Article',
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTextFormField(
                        controller: _titleController,
                        label: 'Article Title',
                        validator: 'Title',
                      ),
                      _buildTextFormField(
                        controller: _categoryController,
                        label: 'Category',
                        validator: 'Category',
                      ),
                      _buildTextFormField(
                        controller: _readTimeController,
                        label: 'Read Time (e.g., 5 mins)',
                        validator: 'Read Time',
                      ),
                      _buildTextFormField(
                        controller: _imageUrlController,
                        label: 'Image URL',
                        validator: 'Image URL',
                      ),
                      _buildTextFormField(
                        controller: _tagsController,
                        label: 'Tags (comma separated)',
                      ),
                      _buildTextFormField(
                        controller: _contentController,
                        label: 'Article Content',
                        validator: 'Content',
                        maxLines: 10,
                      ),

                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 4.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Is Trending?',
                                style: TextStyle(fontSize: 16),
                              ),
                              Switch(
                                value: _isTrending,
                                onChanged:
                                    (newValue) =>
                                        setState(() => _isTrending = newValue),
                                activeColor: AppStyles.primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _submitForm,
                        child: Text(
                          widget.article == null
                              ? 'Create Article'
                              : 'Save Changes',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        maxLines: maxLines,
        validator: (value) {
          if (validator != null && (value == null || value.isEmpty)) {
            return '$validator cannot be empty.';
          }
          return null;
        },
      ),
    );
  }
}
