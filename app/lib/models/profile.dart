class Profile {
  final String? id;
  final String? fullName;
  final String? email;
  final String? avatarUrl;

  Profile({this.id, this.fullName, this.email, this.avatarUrl});

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'email': email,
    'avatar_url': avatarUrl,
  };
}
