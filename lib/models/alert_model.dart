class AlertModel {
  final String id;
  final String userId;
  final String asset;
  final String condition;
  final bool active;
  final Timestamp? lastTriggered;

  AlertModel({
    required this.id,
    required this.userId,
    required this.asset,
    required this.condition,
    this.active = true,
    this.lastTriggered,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      asset: json['asset'] ?? '',
      condition: json['condition'] ?? '',
      active: json['active'] ?? true,
      lastTriggered: json['lastTriggered'] as Timestamp?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'asset': asset,
      'condition': condition,
      'active': active,
      'lastTriggered': lastTriggered ?? FieldValue.serverTimestamp(),
    };
  }

  AlertModel copyWith({
    String? id,
    String? userId,
    String? asset,
    String? condition,
    bool? active,
    Timestamp? lastTriggered,
  }) {
    return AlertModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      asset: asset ?? this.asset,
      condition: condition ?? this.condition,
      active: active ?? this.active,
      lastTriggered: lastTriggered ?? this.lastTriggered,
    );
  }
}