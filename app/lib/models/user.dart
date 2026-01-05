import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String? id;
  final String email;
  final String? fullName;
  final String? token;
  final String? avatarUrl;

  const User({
    this.id,
    required this.email,
    this.fullName,
    this.token,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [id, email, fullName, token, avatarUrl];

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? token,
    String? avatarUrl,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      token: token ?? this.token,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'token': token,
      'avatar_url': avatarUrl,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? json['ID']?.toString() ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      token: json['token'],
      avatarUrl: json['avatar_url'] ?? json['avatar'],
    );
  }
}
