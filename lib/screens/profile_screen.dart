import 'package:flutter/material.dart';
import 'package:newsstream/models/user.dart';
import 'package:newsstream/services/auth_service.dart';
import 'package:newsstream/utils/app_styles.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  Future<User?>? _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _loadUserProfile();
  }

  Future<User?> _loadUserProfile() async {
    // Di sini kita asumsikan Anda perlu mengambil detail user dari API.
    // Jika data user sudah tersedia setelah login, Anda bisa meneruskannya
    // melalui constructor untuk menghindari pemanggilan API berulang.
    // Untuk contoh ini, kita akan membuatnya seolah-olah mengambil data baru.
    // (Dalam kasus nyata, Anda mungkin perlu menambahkan fungsi `getProfile` di `AuthService`)

    // Untuk sekarang, kita akan membuat data dummy berdasarkan apa yang ada di model
    // karena tidak ada endpoint 'get my profile' di service.
    // Ganti dengan implementasi nyata jika API-nya ada.
    return User(
        id: "sample_id",
        email: "user@example.com",
        name: "Nama Pengguna",
        title: "Pembaca Berita",
        avatar: "https://via.placeholder.com/150");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: FutureBuilder<User?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final user = snapshot.data!;
            return _buildProfileView(user);
          } else {
            return const Center(child: Text('User not found.'));
          }
        },
      ),
    );
  }

  Widget _buildProfileView(User user) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Center(
          child: CircleAvatar(
            radius: 60,
            backgroundImage: NetworkImage(user.avatar),
            backgroundColor: AppStyles.backgroundColor,
          ),
        ),
        const SizedBox(height: 24),
        _buildInfoCard(
          icon: Icons.person_outline,
          title: 'Name',
          subtitle: user.name,
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          icon: Icons.email_outlined,
          title: 'Email',
          subtitle: user.email,
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          icon: Icons.work_outline,
          title: 'Title',
          subtitle: user.title,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () async {
            await _authService.logout();
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
          ),
          child: const Text('Logout'),
        ),
      ],
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String subtitle}) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppStyles.primaryColor),
        title: Text(title, style: AppStyles.metadata),
        subtitle: Text(subtitle, style: AppStyles.bodyText.copyWith(color: AppStyles.primaryTextColor)),
      ),
    );
  }
}