import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String username;
  final String email;
  final String password;
  final String fullName;
  final String birthDate;
  final String phone;
  final bool access;
  final String expirationDate;
  final bool twoFactorAuth;
  final String twoFactorCode;
  final String otp;
  final String userKey;
  final String notificationMessage;
  final String createdAt;
  final String? profileImage;
  final String role;
  final bool blocked;
  final int failedAttempts;
  final String? blockedUntil;
  final bool themeBlack;
  final String primaryColor;
  final String bio;
  final List<String> followedUsers;
  final List<String> watchlists;
  final Map<String, dynamic> preferences;
  final int points;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.fullName,
    required this.birthDate,
    required this.phone,
    required this.access,
    required this.expirationDate,
    required this.twoFactorAuth,
    required this.twoFactorCode,
    required this.otp,
    required this.userKey,
    required this.notificationMessage,
    required this.createdAt,
    this.profileImage,
    required this.role,
    required this.blocked,
    required this.failedAttempts,
    this.blockedUntil,
    required this.themeBlack,
    required this.primaryColor,
    this.bio = '',
    this.followedUsers = const [],
    this.watchlists = const [],
    this.preferences = const {},
    this.points = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      fullName: json['full_name'] ?? '',
      birthDate: json['birth_date'] ?? '',
      phone: json['phone'] ?? '',
      access: json['access'] ?? false,
      expirationDate: json['expiration_date'] ?? '',
      twoFactorAuth: json['two_factor_auth'] ?? false,
      twoFactorCode: json['two_factor_code'] ?? '',
      otp: json['otp'] ?? '',
      userKey: json['user_key'] ?? '',
      notificationMessage: json['notification_message'] ?? '',
      createdAt: json['created_at'] ?? '',
      profileImage: json['profile_image'],
      role: json['role'] ?? 'user',
      blocked: json['blocked'] ?? false,
      failedAttempts: json['failed_attempts'] ?? 0,
      blockedUntil: json['blocked_until'],
      themeBlack: json['theme_black'] ?? false,
      primaryColor: json['primary_color'] ?? 'purple',
      bio: json['bio'] ?? '',
      followedUsers: List<String>.from(json['followed_users'] ?? []),
      watchlists: List<String>.from(json['watchlists'] ?? []),
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      points: json['points'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'full_name': fullName,
      'birth_date': birthDate,
      'phone': phone,
      'access': access,
      'expiration_date': expirationDate,
      'two_factor_auth': twoFactorAuth,
      'two_factor_code': twoFactorCode,
      'otp': otp,
      'user_key': userKey,
      'notification_message': notificationMessage,
      'created_at': createdAt,
      'profile_image': profileImage,
      'role': role,
      'blocked': blocked,
      'failed_attempts': failedAttempts,
      'blocked_until': blockedUntil,
      'theme_black': themeBlack,
      'primary_color': primaryColor,
      'bio': bio,
      'followed_users': followedUsers,
      'watchlists': watchlists,
      'preferences': preferences,
      'points': points,
    };
  }
}