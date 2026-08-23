import 'package:enum_to_string/enum_to_string.dart';

class TransactionModel {
  String? id;
  String date;
  double amount;
  String note;
  TransactionType type;
  String categoryId;
  String categoryName;
  String? walletId;
  String? walletName;

  TransactionModel({
    this.id,
    required this.date,
    required this.amount,
    required this.note,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    this.walletId,
    this.walletName,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json, [String? documentId]) {
    return TransactionModel(
      id: documentId,
      date: json['date'],
      amount: (json['amount'] as num).toDouble(),
      note: json['note'],
      type: EnumToString.fromString(TransactionType.values, json['type'])!,
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      walletId: json['walletId'],
      walletName: json['walletName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'amount': amount,
      'note': note,
      'type': EnumToString.convertToString(type),
      'categoryId': categoryId,
      'categoryName': categoryName,
      'walletId': walletId,
      'walletName': walletName,
    };
  }
}

enum TransactionType { income, expense }
