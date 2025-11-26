// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blok_completion.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BlokCompletionAdapter extends TypeAdapter<BlokCompletion> {
  @override
  final int typeId = 6;

  @override
  BlokCompletion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BlokCompletion(
      id: fields[0] as String,
      blokId: fields[1] as String,
      sagId: fields[2] as String,
      completionDate: fields[3] as String,
      completionType: fields[4] as String,
      previousAmount: fields[5] as double,
      newAmount: fields[6] as double,
      amountCompleted: fields[7] as double,
      user: fields[8] as String,
      note: fields[9] as String?,
      createdAt: fields[10] as String,
    );
  }

  @override
  void write(BinaryWriter writer, BlokCompletion obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.blokId)
      ..writeByte(2)
      ..write(obj.sagId)
      ..writeByte(3)
      ..write(obj.completionDate)
      ..writeByte(4)
      ..write(obj.completionType)
      ..writeByte(5)
      ..write(obj.previousAmount)
      ..writeByte(6)
      ..write(obj.newAmount)
      ..writeByte(7)
      ..write(obj.amountCompleted)
      ..writeByte(8)
      ..write(obj.user)
      ..writeByte(9)
      ..write(obj.note)
      ..writeByte(10)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlokCompletionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
