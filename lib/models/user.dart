import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String pin;

  @HiveField(3)
  String role; // 'tekniker', 'bogholder', 'admin'

  /// Liste af feature-keys som brugeren må se (fx 'rentabilitet', 'faktura', osv.)
  @HiveField(4)
  List<String>? enabledFeatures;

  @HiveField(5)
  String createdAt;

  /// FCM token for push notifications (device-specific)
  @HiveField(6)
  String? fcmToken;

  User({
    required this.id,
    required this.name,
    required this.pin,
    required this.role,
    this.enabledFeatures,
    required this.createdAt,
    this.fcmToken,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'pin': pin,
        'role': role,
        'enabledFeatures': enabledFeatures,
        'createdAt': createdAt,
        'fcmToken': fcmToken,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        pin: json['pin'] as String,
        role: json['role'] as String,
        enabledFeatures: (json['enabledFeatures'] as List<dynamic>?)?.cast<String>(),
        createdAt: json['createdAt'] as String,
        fcmToken: json['fcmToken'] as String?,
      );
}
