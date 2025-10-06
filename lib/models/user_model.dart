import 'package:flutter/material.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String password;
  final String fullName;
  final String birthDate;
  final String phone;
  final bool access;
  final DateTime expirationDate;
  final bool twoFactorAuth;
  final String userKey;
  final String notificationMessage;
  final DateTime createdAt;
  final String profileImage;
  final String role;
  final bool blocked;
  final int failedAttempts;
  final DateTime? blockedUntil;
  final String twoFactorCode;
  final String otp;

  DateTime? lastLogin;

  User({
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
    required this.userKey,
    required this.notificationMessage,
    required this.createdAt,
    required this.profileImage,
    required this.role,
    this.blocked = false,
    this.failedAttempts = 0,
    this.blockedUntil,
    required this.twoFactorCode,
    this.otp = '',
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      fullName: json['full_name'] ?? '',
      birthDate: json['birth_date'] ?? '',
      phone: json['phone'] ?? '',
      access: json['access'] ?? false,
      expirationDate: DateTime.parse(json['expiration_date']),
      twoFactorAuth: json['two_factor_auth'] ?? false,
      userKey: json['user_key'] ?? '',
      notificationMessage: json['notification_message'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      profileImage: json['profile_image'] ?? '',
      role: json['role'] ?? 'user',
      blocked: json['blocked'] ?? false,
      failedAttempts: json['failed_attempts'] ?? 0,
      blockedUntil: json['blocked_until'] != null
          ? DateTime.parse(json['blocked_until'])
          : null,
      twoFactorCode: json['two_factor_code'] ?? '',
      otp: json['otp'] ?? '',
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : null,
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
      'expiration_date': expirationDate.toIso8601String(),
      'two_factor_auth': twoFactorAuth,
      'user_key': userKey,
      'notification_message': notificationMessage,
      'created_at': createdAt.toIso8601String(),
      'profile_image': profileImage,
      'role': role,
      'blocked': blocked,
      'failed_attempts': failedAttempts,
      'blocked_until': blockedUntil?.toIso8601String(),
      'two_factor_code': twoFactorCode,
      'otp': otp,
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? password,
    String? fullName,
    String? birthDate,
    String? phone,
    bool? access,
    DateTime? expirationDate,
    bool? twoFactorAuth,
    String? userKey,
    String? notificationMessage,
    DateTime? createdAt,
    String? profileImage,
    String? role,
    bool? blocked,
    int? failedAttempts,
    DateTime? blockedUntil,
    String? twoFactorCode,
    String? otp,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      birthDate: birthDate ?? this.birthDate,
      phone: phone ?? this.phone,
      access: access ?? this.access,
      expirationDate: expirationDate ?? this.expirationDate,
      twoFactorAuth: twoFactorAuth ?? this.twoFactorAuth,
      userKey: userKey ?? this.userKey,
      notificationMessage: notificationMessage ?? this.notificationMessage,
      createdAt: createdAt ?? this.createdAt,
      profileImage: profileImage ?? this.profileImage,
      role: role ?? this.role,
      blocked: blocked ?? this.blocked,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      blockedUntil: blockedUntil ?? this.blockedUntil,
      twoFactorCode: twoFactorCode ?? this.twoFactorCode,
      otp: otp ?? this.otp,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expirationDate);

  bool get isBlocked {
    if (!blocked) return false;
    if (blockedUntil == null) return true;
    return DateTime.now().isBefore(blockedUntil!);
  }

  int get daysUntilExpiry {
    if (isExpired) return 0;
    return expirationDate.difference(DateTime.now()).inDays;
  }

  String get timeUntilExpiry {
    if (isExpired) return 'Expirada';

    final difference = expirationDate.difference(DateTime.now());
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;

    return '${days}d ${hours}h ${minutes}m';
  }

  String get avatarInitial => fullName.isNotEmpty
      ? fullName.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
      : 'U';

  String get accountStatus {
    if (!access) return 'Desativada';
    if (isBlocked) return 'Bloqueada';
    if (isExpired) return 'Expirada';
    return 'Ativa';
  }

  Color get statusColor {
    if (!access || isBlocked || isExpired) return const Color(0xFFFF3B30);
    return const Color(0xFF34C759);
  }

  String get name => fullName;
  String get avatarUrl => profileImage;
}

class UsersResponse {
  final List<User> users;
  final SystemSettings systemSettings;

  UsersResponse({
    required this.users,
    required this.systemSettings,
  });

  factory UsersResponse.fromJson(Map<String, dynamic> json) {
    return UsersResponse(
      users: (json['users'] as List)
          .map((userJson) => User.fromJson(userJson))
          .toList(),
      systemSettings: SystemSettings.fromJson(json['system_settings'] ?? {}),
    );
  }
}

class SystemSettings {
  final String appName;
  final String version;
  final bool maintenanceMode;
  final int maxLoginAttempts;
  final int sessionTimeout;
  final bool requirePasswordChange;

  SystemSettings({
    required this.appName,
    required this.version,
    required this.maintenanceMode,
    required this.maxLoginAttempts,
    required this.sessionTimeout,
    required this.requirePasswordChange,
  });

  factory SystemSettings.fromJson(Map<String, dynamic> json) {
    return SystemSettings(
      appName: json['app_name'] ?? 'AuthSystem iOS',
      version: json['version'] ?? '1.0.0',
      maintenanceMode: json['maintenance_mode'] ?? false,
      maxLoginAttempts: json['max_login_attempts'] ?? 3,
      sessionTimeout: json['session_timeout'] ?? 3600,
      requirePasswordChange: json['require_password_change'] ?? false,
    );
  }
}