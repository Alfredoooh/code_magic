import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String name;
  final String nickname;
  final String email;
  final String phoneNumber;
  final String location;
  final DateTime? dateOfBirth;
  final String photoURL;
  final bool isUserBlocked;
  final bool isOnline;
  final bool isPro;
  final bool isPremium;
  final String accountType;
  final double balance;
  final DateTime createdAt;
  final DateTime lastSeen;

  UserModel({
    required this.userId,
    required this.name,
    required this.nickname,
    required this.email,
    required this.phoneNumber,
    this.location = '',
    this.dateOfBirth,
    this.photoURL = '',
    this.isUserBlocked = false,
    this.isOnline = false,
    this.isPro = false,
    this.isPremium = false,
    this.accountType = 'standard',
    this.balance = 0.0,
    required this.createdAt,
    required this.lastSeen,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: doc.id,
      name: data['name'] ?? '',
      nickname: data['nickname'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      location: data['location'] ?? '',
      dateOfBirth: data['dateOfBirth'] != null
          ? (data['dateOfBirth'] as Timestamp).toDate()
          : null,
      photoURL: data['photoURL'] ?? '',
      isUserBlocked: data['isUserBlocked'] ?? false,
      isOnline: data['isOnline'] ?? false,
      isPro: data['isPro'] ?? false,
      isPremium: data['isPremium'] ?? false,
      accountType: data['accountType'] ?? 'standard',
      balance: (data['balance'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastSeen: (data['lastSeen'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'nickname': nickname,
      'email': email,
      'phoneNumber': phoneNumber,
      'location': location,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'photoURL': photoURL,
      'isUserBlocked': isUserBlocked,
      'isOnline': isOnline,
      'isPro': isPro,
      'isPremium': isPremium,
      'accountType': accountType,
      'balance': balance,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSeen': Timestamp.fromDate(lastSeen),
    };
  }

  UserModel copyWith({
    String? name,
    String? nickname,
    String? location,
    DateTime? dateOfBirth,
    String? photoURL,
    bool? isOnline,
    bool? isPro,
    bool? isPremium,
    double? balance,
  }) {
    return UserModel(
      userId: userId,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      email: email,
      phoneNumber: phoneNumber,
      location: location ?? this.location,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      photoURL: photoURL ?? this.photoURL,
      isUserBlocked: isUserBlocked,
      isOnline: isOnline ?? this.isOnline,
      isPro: isPro ?? this.isPro,
      isPremium: isPremium ?? this.isPremium,
      accountType: accountType,
      balance: balance ?? this.balance,
      createdAt: createdAt,
      lastSeen: DateTime.now(),
    );
  }
}

class UserSettings {
  final String userId;
  final String language;
  final String theme;
  final bool notifications;
  final bool twoFactorEnabled;

  UserSettings({
    required this.userId,
    this.language = 'pt',
    this.theme = 'dark',
    this.notifications = true,
    this.twoFactorEnabled = false,
  });

  factory UserSettings.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserSettings(
      userId: doc.id,
      language: data['language'] ?? 'pt',
      theme: data['theme'] ?? 'dark',
      notifications: data['notifications'] ?? true,
      twoFactorEnabled: data['twoFactorEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'language': language,
      'theme': theme,
      'notifications': notifications,
      'twoFactorEnabled': twoFactorEnabled,
    };
  }

  UserSettings copyWith({
    String? language,
    String? theme,
    bool? notifications,
    bool? twoFactorEnabled,
  }) {
    return UserSettings(
      userId: userId,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      notifications: notifications ?? this.notifications,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
    );
  }
}