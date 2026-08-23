import 'package:cloud_firestore/cloud_firestore.dart';

class WalletModel {
  final String id;
  final String userId;
  final String name;
  final DateTime createdAt;

  WalletModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json, String documentId) {
    return WalletModel(
      id: documentId,
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  WalletModel copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? createdAt,
  }) {
    return WalletModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
