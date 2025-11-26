// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'affugter.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AffugterAdapter extends TypeAdapter<Affugter> {
  @override
  final int typeId = 2;

  @override
  Affugter read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Affugter(
      id: fields[0] as String,
      nr: fields[1] as String,
      type: fields[2] as String,
      maerke: fields[3] as String,
      model: fields[4] as String?,
      serie: fields[5] as String?,
      status: fields[6] as String,
      currentSagId: fields[7] as String?,
      note: fields[8] as String?,
      createdAt: fields[9] as String,
      updatedAt: fields[10] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Affugter obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nr)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.maerke)
      ..writeByte(4)
      ..write(obj.model)
      ..writeByte(5)
      ..write(obj.serie)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.currentSagId)
      ..writeByte(8)
      ..write(obj.note)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AffugterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
