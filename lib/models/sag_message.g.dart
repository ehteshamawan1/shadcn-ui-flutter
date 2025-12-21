// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sag_message.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SagMessageAdapter extends TypeAdapter<SagMessage> {
  @override
  final int typeId = 9;

  @override
  SagMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SagMessage(
      id: fields[0] as String,
      sagId: fields[1] as String,
      userId: fields[2] as String,
      userName: fields[3] as String,
      text: fields[4] as String,
      timestamp: fields[5] as String,
      targetUserId: fields[6] as String?,
      targetUserName: fields[7] as String?,
      priority: fields[8] as String?,
      messageType: fields[9] as String?,
      parentMessageId: fields[10] as String?,
      isRead: fields[11] as bool?,
      readAt: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SagMessage obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sagId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.userName)
      ..writeByte(4)
      ..write(obj.text)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.targetUserId)
      ..writeByte(7)
      ..write(obj.targetUserName)
      ..writeByte(8)
      ..write(obj.priority)
      ..writeByte(9)
      ..write(obj.messageType)
      ..writeByte(10)
      ..write(obj.parentMessageId)
      ..writeByte(11)
      ..write(obj.isRead)
      ..writeByte(12)
      ..write(obj.readAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SagMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
