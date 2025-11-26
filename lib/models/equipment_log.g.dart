// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'equipment_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EquipmentLogAdapter extends TypeAdapter<EquipmentLog> {
  @override
  final int typeId = 3;

  @override
  EquipmentLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EquipmentLog(
      id: fields[0] as String,
      sagId: fields[1] as String,
      blokId: fields[2] as String?,
      category: fields[3] as String,
      action: fields[4] as String,
      data: (fields[5] as Map).cast<String, dynamic>(),
      timestamp: fields[6] as String,
      user: fields[7] as String,
      note: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, EquipmentLog obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sagId)
      ..writeByte(2)
      ..write(obj.blokId)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.action)
      ..writeByte(5)
      ..write(obj.data)
      ..writeByte(6)
      ..write(obj.timestamp)
      ..writeByte(7)
      ..write(obj.user)
      ..writeByte(8)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EquipmentLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
