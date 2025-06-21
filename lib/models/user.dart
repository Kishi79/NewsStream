class User {
  final String id;
  final String email;
  final String name;
  final String title;
  final String avatar;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.title,
    required this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'] ?? 'No Name',
      title: json['title'] ?? 'No Title',
      avatar: json['avatar'] ?? 'https://via.placeholder.com/150',
    );
  }
}
