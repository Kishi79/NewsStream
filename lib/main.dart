import 'package:flutter/material.dart';
import 'package:newsstream/utils/app_styles.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/intro_screen.dart'; // <-- IMPORT BARU

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NewsStream App',
      theme: AppStyles.themeData,
      home: const SplashScreen(),
      routes: {
        '/intro': (context) => const IntroScreen(), // <-- ROUTE BARU
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
