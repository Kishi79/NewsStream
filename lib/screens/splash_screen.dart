import 'package:flutter/material.dart';
import 'package:newsstream/services/auth_service.dart';
import 'package:newsstream/utils/app_styles.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- IMPORT BARU

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    // Tunggu beberapa saat untuk menampilkan splash screen
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      // Cek apakah intro screen sudah pernah ditampilkan
      final prefs = await SharedPreferences.getInstance();
      final bool introShown = prefs.getBool('intro_shown') ?? false;

      if (!introShown) {
        // Tandai bahwa intro sudah ditampilkan
        await prefs.setBool('intro_shown', true);
        Navigator.of(context).pushReplacementNamed('/intro');
      } else {
        final authService = AuthService();
        final bool isLoggedIn = await authService.isLoggedIn();

        if (isLoggedIn) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          Navigator.of(context).pushReplacementNamed('/auth');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.newspaper, color: Colors.white, size: 100),
            SizedBox(height: 20),
            Text(
              'NewsStream',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
