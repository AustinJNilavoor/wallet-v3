// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PendingTransactionAdapter extends TypeAdapter<PendingTransaction> {
  @override
  final int typeId = 12;

  @override
  PendingTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingTransaction(
      id: fields[0] as String,
      smsId: fields[1] as String?,
      duplicateKey: fields[2] as String,
      sender: fields[3] as String,
      rawMessage: fields[4] as String,
      smsDate: fields[5] as DateTime,
      createdAt: fields[6] as DateTime?,
      templateId: fields[7] as String?,
      amount: fields[8] as double?,
      transactionDate: fields[9] as DateTime?,
      merchant: fields[10] as String?,
      accountNumber: fields[11] as String?,
      referenceNumber: fields[12] as String?,
      balance: fields[13] as double?,
      description: fields[14] as String?,
      categoryId: fields[15] as String?,
      sourceId: fields[16] as String?,
      destinationSourceId: fields[17] as String?,
      transactionType: fields[18] as String?,
      note: fields[19] as String?,
      status: fields[20] as PendingTransactionStatus,
      confidence: fields[21] as double,
      parsingSuccessful: fields[22] as bool,
      missingFields: (fields[23] as List).cast<String>(),
      customFields: (fields[24] as Map).cast<String, String>(),
      updatedAt: fields[25] as DateTime?,
      reviewedAt: fields[26] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PendingTransaction obj) {
    writer
      ..writeByte(27)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.smsId)
      ..writeByte(2)
      ..write(obj.duplicateKey)
      ..writeByte(3)
      ..write(obj.sender)
      ..writeByte(4)
      ..write(obj.rawMessage)
      ..writeByte(5)
      ..write(obj.smsDate)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.templateId)
      ..writeByte(8)
      ..write(obj.amount)
      ..writeByte(9)
      ..write(obj.transactionDate)
      ..writeByte(10)
      ..write(obj.merchant)
      ..writeByte(11)
      ..write(obj.accountNumber)
      ..writeByte(12)
      ..write(obj.referenceNumber)
      ..writeByte(13)
      ..write(obj.balance)
      ..writeByte(14)
      ..write(obj.description)
      ..writeByte(15)
      ..write(obj.categoryId)
      ..writeByte(16)
      ..write(obj.sourceId)
      ..writeByte(17)
      ..write(obj.destinationSourceId)
      ..writeByte(18)
      ..write(obj.transactionType)
      ..writeByte(19)
      ..write(obj.note)
      ..writeByte(20)
      ..write(obj.status)
      ..writeByte(21)
      ..write(obj.confidence)
      ..writeByte(22)
      ..write(obj.parsingSuccessful)
      ..writeByte(23)
      ..write(obj.missingFields)
      ..writeByte(24)
      ..write(obj.customFields)
      ..writeByte(25)
      ..write(obj.updatedAt)
      ..writeByte(26)
      ..write(obj.reviewedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PendingTransactionStatusAdapter
    extends TypeAdapter<PendingTransactionStatus> {
  @override
  final int typeId = 11;

  @override
  PendingTransactionStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PendingTransactionStatus.pending;
      case 1:
        return PendingTransactionStatus.approved;
      case 2:
        return PendingTransactionStatus.rejected;
      default:
        return PendingTransactionStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, PendingTransactionStatus obj) {
    switch (obj) {
      case PendingTransactionStatus.pending:
        writer.writeByte(0);
        break;
      case PendingTransactionStatus.approved:
        writer.writeByte(1);
        break;
      case PendingTransactionStatus.rejected:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingTransactionStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
