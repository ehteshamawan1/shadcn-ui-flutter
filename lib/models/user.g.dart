// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 0;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final rawFeatures = fields[4];
    final features = rawFeatures is List ? rawFeatures.cast<String>() : null;
    final createdAt = fields[5] is String
        ? fields[5] as String
        : (fields[4] is String ? fields[4] as String : '');
    return User(
      id: fields[0] as String,
      name: fields[1] as String,
      pin: fields[2] as String,
      role: fields[3] as String,
      enabledFeatures: features,
      createdAt: createdAt,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.pin)
      ..writeByte(3)
      ..write(obj.role)
      ..writeByte(4)
      ..write(obj.enabledFeatures)
      ..writeByte(5)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
