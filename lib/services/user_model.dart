class UserModel {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final String? profileImage;
  final bool admin;
  final bool access;
  final bool pro;
  final int tokens;
  final String theme;
  final String language;
  final String? expirationDate;
  final String? phone;
  final String? birthDate;
  final bool isOnline;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.profileImage,
    required this.admin,
    required this.access,
    required this.pro,
    required this.tokens,
    required this.theme,
    required this.language,
    this.expirationDate,
    this.phone,
    this.birthDate,
    this.isOnline = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      fullName: map['full_name'] ?? '',
      profileImage: map['profile_image'],
      admin: map['admin'] ?? false,
      access: map['access'] ?? true,
      pro: map['pro'] ?? false,
      tokens: map['tokens'] ?? 50,
      theme: map['theme'] ?? 'dark',
      language: map['language'] ?? 'pt',
      expirationDate: map['expiration_date'],
      phone: map['phone'],
      birthDate: map['birth_date'],
      isOnline: map['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'profile_image': profileImage,
      'admin': admin,
      'access': access,
      'pro': pro,
      'tokens': tokens,
      'theme': theme,
      'language': language,
      'expiration_date': expirationDate,
      'phone': phone,
      'birth_date': birthDate,
      'isOnline': isOnline,
    };
  }
}