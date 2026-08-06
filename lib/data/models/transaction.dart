// lib/data/models/transaction.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum TransactionType {
  revenu,
  depense,
  transfert,
}

class TransactionModel extends Equatable {
  final String? id;
  final String uuid;
  final String utilisateurId;  // ← Changé de int à String
  final String portefeuilleId; // ← Changé de int à String
  final String? portefeuilleDestId; // ← Changé de int? à String?
  final double montant;
  final TransactionType type;
  final String categorieId;
  final String categorieLabel;
  final String categorieEmoji;
  final String? note;
  final DateTime dateTransaction;
  final DateTime createdAt;

  const TransactionModel({
    this.id,
    required this.uuid,
    required this.utilisateurId,
    required this.portefeuilleId,
    this.portefeuilleDestId,
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

  Map<String, dynamic> toFirestore() => {
    'uuid': uuid,
    'utilisateurId': utilisateurId,
    'portefeuilleId': portefeuilleId,
    'portefeuilleDestId': portefeuilleDestId,
    'montant': montant,
    'type': type.name,
    'categorieId': categorieId,
    'categorieLabel': categorieLabel,
    'categorieEmoji': categorieEmoji,
    'note': note,
    'dateTransaction': dateTransaction.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      uuid: data['uuid'] ?? '',
      utilisateurId: data['utilisateurId'] ?? '',
      portefeuilleId: data['portefeuilleId'] ?? '',
      portefeuilleDestId: data['portefeuilleDestId'],
      montant: (data['montant'] as num?)?.toDouble() ?? 0,
      type: TransactionType.values.firstWhere(
            (e) => e.name == data['type'],
        orElse: () => TransactionType.depense,
      ),
      categorieId: data['categorieId'] ?? 'autre',
      categorieLabel: data['categorieLabel'] ?? 'Autre',
      categorieEmoji: data['categorieEmoji'] ?? '📌',
      note: data['note'],
      dateTransaction: data['dateTransaction'] != null
          ? DateTime.parse(data['dateTransaction'])
          : DateTime.now(),
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uuid': uuid,
    'utilisateurId': utilisateurId,
    'portefeuilleId': portefeuilleId,
    'portefeuilleDestId': portefeuilleDestId,
    'montant': montant,
    'type': type.name,
    'categorieId': categorieId,
    'categorieLabel': categorieLabel,
    'categorieEmoji': categorieEmoji,
    'note': note,
    'dateTransaction': dateTransaction.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
    id: json['id'],
    uuid: json['uuid'] ?? '',
    utilisateurId: json['utilisateurId'] ?? '',
    portefeuilleId: json['portefeuilleId'] ?? '',
    portefeuilleDestId: json['portefeuilleDestId'],
    montant: (json['montant'] as num?)?.toDouble() ?? 0,
    type: TransactionType.values.firstWhere(
          (e) => e.name == json['type'],
      orElse: () => TransactionType.depense,
    ),
    categorieId: json['categorieId'] ?? 'autre',
    categorieLabel: json['categorieLabel'] ?? 'Autre',
    categorieEmoji: json['categorieEmoji'] ?? '📌',
    note: json['note'],
    dateTransaction: json['dateTransaction'] != null
        ? DateTime.parse(json['dateTransaction'])
        : DateTime.now(),
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
  );

  TransactionModel copyWith({
    String? id,
    String? uuid,
    String? utilisateurId,
    String? portefeuilleId,
    String? portefeuilleDestId,
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
      uuid: uuid ?? this.uuid,
      utilisateurId: utilisateurId ?? this.utilisateurId,
      portefeuilleId: portefeuilleId ?? this.portefeuilleId,
      portefeuilleDestId: portefeuilleDestId ?? this.portefeuilleDestId,
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

  @override
  List<Object?> get props => [
    id,
    uuid,
    utilisateurId,
    portefeuilleId,
    portefeuilleDestId,
    montant,
    type,
    categorieId,
    categorieLabel,
    categorieEmoji,
    note,
    dateTransaction,
    createdAt,
  ];
}