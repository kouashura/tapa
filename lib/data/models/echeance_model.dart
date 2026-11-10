// lib/data/models/echeance_model.dart

/// Modèle échéance pour Firestore
class EcheanceModel {
  final String id;
  final String uid;
  final String titre;
  final String description;
  final double montant;
  final DateTime dateEcheance;
  final String type; // 'mensuelle', 'hebdomadaire', 'unique'
  final String statut; // 'en_attente', 'payee', 'en_retard'
  final String descriptionRecurrence;
  final String descriptionRappel;
  final DateTime createdAt;
  final DateTime updatedAt;

  EcheanceModel({
    required this.id,
    required this.uid,
    required this.titre,
    required this.description,
    required this.montant,
    required this.dateEcheance,
    required this.type,
    required this.statut,
    this.descriptionRecurrence = '',
    this.descriptionRappel = '',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get estEnRetard =>
      statut != 'payee' && dateEcheance.isBefore(DateTime.now());

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'titre': titre,
      'description': description,
      'montant': montant,
      'dateEcheance': dateEcheance,
      'type': type,
      'statut': statut,
      'descriptionRecurrence': descriptionRecurrence,
      'descriptionRappel': descriptionRappel,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory EcheanceModel.fromMap(Map<String, dynamic> map, String id) {
    return EcheanceModel(
      id: id,
      uid: map['uid'] ?? '',
      titre: map['titre'] ?? '',
      description: map['description'] ?? '',
      montant: (map['montant'] as num?)?.toDouble() ?? 0,
      dateEcheance: map['dateEcheance']?.toDate() ?? DateTime.now(),
      type: map['type'] ?? 'unique',
      statut: map['statut'] ?? 'en_attente',
      descriptionRecurrence: map['descriptionRecurrence'] ?? '',
      descriptionRappel: map['descriptionRappel'] ?? '',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  EcheanceModel copyWith({
    String? id,
    String? uid,
    String? titre,
    String? description,
    double? montant,
    DateTime? dateEcheance,
    String? type,
    String? statut,
    String? descriptionRecurrence,
    String? descriptionRappel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EcheanceModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      montant: montant ?? this.montant,
      dateEcheance: dateEcheance ?? this.dateEcheance,
      type: type ?? this.type,
      statut: statut ?? this.statut,
      descriptionRecurrence:
          descriptionRecurrence ?? this.descriptionRecurrence,
      descriptionRappel: descriptionRappel ?? this.descriptionRappel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
