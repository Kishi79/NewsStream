import 'package:flutter/material.dart';
import 'package:newsstream/utils/app_styles.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.article,
                size: 100,
                color: AppStyles.primaryColor,
              ),
              const SizedBox(height: 24),
              const Text(
                'Selamat Datang di NewsStream',
                textAlign: TextAlign.center,
                style: AppStyles.h1,
              ),
              const SizedBox(height: 16),
              Text(
                'Aplikasi portal berita terlengkap dan terpercaya untuk Anda. Jelajahi ribuan artikel dari berbagai kategori.',
                textAlign: TextAlign.center,
                style: AppStyles.bodyText.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  // Navigasi ke halaman otentikasi
                  Navigator.of(context).pushReplacementNamed('/auth');
                },
                child: const Text('Mulai Sekarang'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
