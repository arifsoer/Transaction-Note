import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:transaction_note/models/transaction.dart';

class CategoryModel {
  final String id;
  final String userId;
  final String name;
  final TransactionType type;
  final String iconName;
  final double budget;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.iconName,
    this.budget = 0.0,
    required this.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json, String documentId) {
    return CategoryModel(
      id: documentId,
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: EnumToString.fromString(TransactionType.values, json['type'] as String? ?? 'expense') ?? TransactionType.expense,
      iconName: json['iconName'] as String? ?? 'label',
      budget: (json['budget'] as num?)?.toDouble() ?? 0.0,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'type': EnumToString.convertToString(type),
      'iconName': iconName,
      'budget': budget,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  CategoryModel copyWith({
    String? id,
    String? userId,
    String? name,
    TransactionType? type,
    String? iconName,
    double? budget,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      iconName: iconName ?? this.iconName,
      budget: budget ?? this.budget,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
