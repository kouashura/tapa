// lib/data/models/wallet.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class WalletModel extends Equatable {
  final int? id;
  final String uuid;
  final int utilisateurId;
  final String nom;
  final String type;
  final String emoji;
  final double solde;
  final double seuilAlerte;
  final DateTime? updatedAt;
  final DateTime createdAt;

  const WalletModel({
    this.id,
    required this.uuid,
    required this.utilisateurId,
    required this.nom,
    required this.type,
    required this.emoji,
    required this.solde,
    required this.seuilAlerte,
    this.updatedAt,
    required this.createdAt,
  });

  bool get estPresqueVide => seuilAlerte > 0 && solde <= seuilAlerte;

  Map<String, dynamic> toFirestore() => {
    'uuid': uuid,
    'utilisateurId': utilisateurId,
    'nom': nom,
    'type': type,
    'emoji': emoji,
    'solde': solde,
    'seuilAlerte': seuilAlerte,
    'updatedAt': updatedAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory WalletModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WalletModel(
      id: int.tryParse(doc.id),
      uuid: data['uuid'] ?? '',
      utilisateurId: data['utilisateurId'] ?? 0,
      nom: data['nom'] ?? '',
      type: data['type'] ?? 'compte',
      emoji: data['emoji'] ?? '💰',
      solde: (data['solde'] as num?)?.toDouble() ?? 0,
      seuilAlerte: (data['seuilAlerte'] as num?)?.toDouble() ?? 5000,
      updatedAt: data['updatedAt'] != null ? DateTime.parse(data['updatedAt']) : null,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uuid': uuid,
    'utilisateurId': utilisateurId,
    'nom': nom,
    'type': type,
    'emoji': emoji,
    'solde': solde,
    'seuilAlerte': seuilAlerte,
    'updatedAt': updatedAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory WalletModel.fromJson(Map<String, dynamic> json) => WalletModel(
    id: json['id'],
    uuid: json['uuid'] ?? '',
    utilisateurId: json['utilisateurId'] ?? 0,
    nom: json['nom'] ?? '',
    type: json['type'] ?? 'compte',
    emoji: json['emoji'] ?? '💰',
    solde: (json['solde'] as num?)?.toDouble() ?? 0,
    seuilAlerte: (json['seuilAlerte'] as num?)?.toDouble() ?? 5000,
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
  );

  WalletModel copyWith({
    int? id,
    String? uuid,
    int? utilisateurId,
    String? nom,
    String? type,
    String? emoji,
    double? solde,
    double? seuilAlerte,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) => WalletModel(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    utilisateurId: utilisateurId ?? this.utilisateurId,
    nom: nom ?? this.nom,
    type: type ?? this.type,
    emoji: emoji ?? this.emoji,
    solde: solde ?? this.solde,
    seuilAlerte: seuilAlerte ?? this.seuilAlerte,
    updatedAt: updatedAt ?? this.updatedAt,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  List<Object?> get props => [
    id,
    uuid,
    utilisateurId,
    nom,
    type,
    emoji,
    solde,
    seuilAlerte,
    updatedAt,
    createdAt,
  ];
}