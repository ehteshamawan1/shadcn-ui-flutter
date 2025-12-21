// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sag.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SagAdapter extends TypeAdapter<Sag> {
  @override
  final int typeId = 1;

  @override
  Sag read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Sag(
      id: fields[0] as String,
      sagsnr: fields[1] as String,
      adresse: fields[2] as String,
      byggeleder: fields[3] as String,
      byggelederEmail: fields[4] as String?,
      byggelederTlf: fields[5] as String?,
      bygherre: fields[6] as String?,
      cvrNr: fields[7] as String?,
      kundensSagsref: fields[8] as String?,
      beskrivelse: fields[9] as String?,
      status: fields[10] as String,
      aktiv: fields[11] as bool,
      arkiveret: fields[12] as bool?,
      arkiveretDato: fields[13] as String?,
      sagType: fields[14] as String?,
      region: fields[15] as String?,
      oprettetAf: fields[16] as String,
      oprettetDato: fields[17] as String,
      opdateretDato: fields[18] as String,
      createdAt: fields[19] as String?,
      updatedAt: fields[20] as String?,
      needsAttention: fields[21] as bool?,
      attentionNote: fields[22] as String?,
      attentionAcknowledgedAt: fields[23] as String?,
      attentionAcknowledgedBy: fields[24] as String?,
      postnummer: fields[25] as String?,
      by: fields[26] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Sag obj) {
    writer
      ..writeByte(27)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sagsnr)
      ..writeByte(2)
      ..write(obj.adresse)
      ..writeByte(3)
      ..write(obj.byggeleder)
      ..writeByte(4)
      ..write(obj.byggelederEmail)
      ..writeByte(5)
      ..write(obj.byggelederTlf)
      ..writeByte(6)
      ..write(obj.bygherre)
      ..writeByte(7)
      ..write(obj.cvrNr)
      ..writeByte(8)
      ..write(obj.kundensSagsref)
      ..writeByte(9)
      ..write(obj.beskrivelse)
      ..writeByte(10)
      ..write(obj.status)
      ..writeByte(11)
      ..write(obj.aktiv)
      ..writeByte(12)
      ..write(obj.arkiveret)
      ..writeByte(13)
      ..write(obj.arkiveretDato)
      ..writeByte(14)
      ..write(obj.sagType)
      ..writeByte(15)
      ..write(obj.region)
      ..writeByte(16)
      ..write(obj.oprettetAf)
      ..writeByte(17)
      ..write(obj.oprettetDato)
      ..writeByte(18)
      ..write(obj.opdateretDato)
      ..writeByte(19)
      ..write(obj.createdAt)
      ..writeByte(20)
      ..write(obj.updatedAt)
      ..writeByte(21)
      ..write(obj.needsAttention)
      ..writeByte(22)
      ..write(obj.attentionNote)
      ..writeByte(23)
      ..write(obj.attentionAcknowledgedAt)
      ..writeByte(24)
      ..write(obj.attentionAcknowledgedBy)
      ..writeByte(25)
      ..write(obj.postnummer)
      ..writeByte(26)
      ..write(obj.by);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SagAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
