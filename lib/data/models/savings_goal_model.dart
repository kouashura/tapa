// lib/data/models/savings_goal_model.dart

/// Modèle objectif d'épargne
class SavingsGoalModel {
  final String id;
  final String uid;
  final String nom;
  final double montantCible;
  final double montantActuel;
  final DateTime? dateLimite;
  final String walletId;
  final bool estAtteint;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavingsGoalModel({
    required this.id,
    required this.uid,
    required this.nom,
    required this.montantCible,
    required this.montantActuel,
    this.dateLimite,
    required this.walletId,
    required this.estAtteint,
    required this.createdAt,
    required this.updatedAt,
  });

  double get progression =>
      montantCible > 0 ? (montantActuel / montantCible).clamp(0.0, 1.0) : 0.0;

  double get progressionPct => progression * 100;

  double get resteAEpargner =>
      (montantCible - montantActuel).clamp(0.0, double.infinity);

  int get joursRestants => dateLimite?.difference(DateTime.now()).inDays ?? 0;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nom': nom,
      'montantCible': montantCible,
      'montantActuel': montantActuel,
      'dateLimite': dateLimite,
      'walletId': walletId,
      'estAtteint': estAtteint,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory SavingsGoalModel.fromMap(Map<String, dynamic> map, String id) {
    return SavingsGoalModel(
      id: id,
      uid: map['uid'] ?? '',
      nom: map['nom'] ?? '',
      montantCible: (map['montantCible'] as num?)?.toDouble() ?? 0,
      montantActuel: (map['montantActuel'] as num?)?.toDouble() ?? 0,
      dateLimite: map['dateLimite']?.toDate(),
      walletId: map['walletId'] ?? '',
      estAtteint: map['estAtteint'] ?? false,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  SavingsGoalModel copyWith({
    String? id,
    String? uid,
    String? nom,
    double? montantCible,
    double? montantActuel,
    DateTime? dateLimite,
    String? walletId,
    bool? estAtteint,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavingsGoalModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      nom: nom ?? this.nom,
      montantCible: montantCible ?? this.montantCible,
      montantActuel: montantActuel ?? this.montantActuel,
      dateLimite: dateLimite ?? this.dateLimite,
      walletId: walletId ?? this.walletId,
      estAtteint: estAtteint ?? this.estAtteint,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
