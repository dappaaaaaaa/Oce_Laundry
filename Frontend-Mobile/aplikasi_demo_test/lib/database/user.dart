class User {
  int? id;
  String email;
  String username;
  String? password;
  String? token;

  User({
    this.id,
    required this.email,
    required this.username,
    this.password,

    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['name'],
      email: json['email'],
      password: '',
      token: json['token'],
    );
  }
}
