import 'package:flutter/material.dart';
import 'package:newsstream/utils/app_styles.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _avatarController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  void _submitAuthForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        await _authService.login(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await _authService.register(
          email: _emailController.text,
          password: _passwordController.text,
          name: _nameController.text,
          title:
              _titleController.text.isNotEmpty ? _titleController.text : null,
          avatar:
              _avatarController.text.isNotEmpty ? _avatarController.text : null,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please log in.'),
          ),
        );
        setState(() {
          _isLogin = true;
        });
      }
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
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
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _titleController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppStyles.primaryColor, AppStyles.primaryColorLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.newspaper, color: Colors.white, size: 80),
                const SizedBox(height: 16),
                const Text(
                  'Welcome to NewsStream',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'Sign in to continue' : 'Create an account',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 40),
                Card(
                  elevation: 8.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'Email Address',
                              prefixIcon: Icon(Icons.alternate_email),
                            ),
                            validator: (value) {
                              if (value == null || !value.contains('@')) {
                                return 'Please enter a valid email address.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              hintText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return 'Password must be at least 6 characters.';
                              }
                              return null;
                            },
                          ),
                          if (!_isLogin) ..._buildRegisterFields(),
                          const SizedBox(height: 24),
                          if (_isLoading)
                            const CircularProgressIndicator()
                          else
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _submitAuthForm,
                                child: Text(_isLogin ? 'Login' : 'Register'),
                              ),
                            ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLogin = !_isLogin;
                              });
                            },
                            child: Text(
                              _isLogin
                                  ? 'Don\'t have an account? Register'
                                  : 'Already have an account? Login',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRegisterFields() {
    return [
      const SizedBox(height: 16),
      TextFormField(
        controller: _nameController,
        decoration: const InputDecoration(
          hintText: 'Full Name',
          prefixIcon: Icon(Icons.person_outline),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your full name.';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _titleController,
        decoration: const InputDecoration(
          hintText: 'Title (e.g., Software Developer)',
          prefixIcon: Icon(Icons.work_outline),
        ),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _avatarController,
        decoration: const InputDecoration(
          hintText: 'Avatar URL (Optional)',
          prefixIcon: Icon(Icons.image_outlined),
        ),
      ),
    ];
  }
}
