class User {
  User({required this.id, required this.email, required this.nickname});

  final String id;
  final String email;
  final String nickname;

  Map<String, dynamic> toJson() => {'id': id, 'email': email, 'nickname': nickname};

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] as String,
        email: j['email'] as String,
        nickname: j['nickname'] as String? ?? '',
      );
}
