// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blok.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BlokAdapter extends TypeAdapter<Blok> {
  @override
  final int typeId = 5;

  @override
  Blok read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Blok(
      id: fields[0] as String,
      sagId: fields[1] as String,
      navn: fields[2] as String,
      beskrivelse: fields[3] as String?,
      pricingModel: fields[4] as String,
      antalLejligheder: fields[5] as int,
      antalM2: fields[6] as double,
      fastPrisPrLejlighed: fields[7] as double,
      fastPrisPrM2: fields[8] as double,
      faerdigmeldteLejligheder: fields[9] as int,
      faerdigmeldteM2: fields[10] as double,
      slutDato: fields[11] as String?,
      createdAt: fields[12] as String,
      updatedAt: fields[13] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Blok obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sagId)
      ..writeByte(2)
      ..write(obj.navn)
      ..writeByte(3)
      ..write(obj.beskrivelse)
      ..writeByte(4)
      ..write(obj.pricingModel)
      ..writeByte(5)
      ..write(obj.antalLejligheder)
      ..writeByte(6)
      ..write(obj.antalM2)
      ..writeByte(7)
      ..write(obj.fastPrisPrLejlighed)
      ..writeByte(8)
      ..write(obj.fastPrisPrM2)
      ..writeByte(9)
      ..write(obj.faerdigmeldteLejligheder)
      ..writeByte(10)
      ..write(obj.faerdigmeldteM2)
      ..writeByte(11)
      ..write(obj.slutDato)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlokAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
