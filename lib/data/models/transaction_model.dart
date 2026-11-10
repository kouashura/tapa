// lib/data/models/transaction_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Types de transactions
enum TransactionType {
  revenu,
  depense,
  transfert,
}

/// Modèle transaction pour Firestore
class TransactionModel {
  final String id;
  final String uid;
  final String walletId;
  final double montant;
  final TransactionType type;
  final String categorieId;
  final String categorieLabel;
  final String categorieEmoji;
  final String? note;
  final DateTime dateTransaction;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.uid,
    required this.walletId,
    required this.montant,
    required this.type,
    required this.categorieId,
    required this.categorieLabel,
    required this.categorieEmoji,
    this.note,
    required this.dateTransaction,
    required this.createdAt,
  });

  bool get isRevenu => type == TransactionType.revenu;
  bool get isDepense => type == TransactionType.depense;
  bool get isTransfert => type == TransactionType.transfert;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'walletId': walletId,
      'montant': montant,
      'type': type.name,
      'categorieId': categorieId,
      'categorieLabel': categorieLabel,
      'categorieEmoji': categorieEmoji,
      'note': note,
      'dateTransaction': Timestamp.fromDate(dateTransaction),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      uid: map['uid'] ?? '',
      walletId: map['walletId'] ?? '',
      montant: (map['montant'] as num?)?.toDouble() ?? 0,
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.depense,
      ),
      categorieId: map['categorieId'] ?? 'autre',
      categorieLabel: map['categorieLabel'] ?? 'Autre',
      categorieEmoji: map['categorieEmoji'] ?? '📝',
      note: map['note'],
      dateTransaction: map['dateTransaction'] != null
          ? DateTime.parse(map['dateTransaction'])
          : DateTime.now(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  TransactionModel copyWith({
    String? id,
    String? uid,
    String? walletId,
    double? montant,
    TransactionType? type,
    String? categorieId,
    String? categorieLabel,
    String? categorieEmoji,
    String? note,
    DateTime? dateTransaction,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      walletId: walletId ?? this.walletId,
      montant: montant ?? this.montant,
      type: type ?? this.type,
      categorieId: categorieId ?? this.categorieId,
      categorieLabel: categorieLabel ?? this.categorieLabel,
      categorieEmoji: categorieEmoji ?? this.categorieEmoji,
      note: note ?? this.note,
      dateTransaction: dateTransaction ?? this.dateTransaction,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
