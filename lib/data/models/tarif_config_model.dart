// lib/data/models/tarif_config_model.dart

class TarifConfigModel {
  final String id;
  // Base par catégorie de marque (FCFA/mois)
  final double basePremium;
  final double baseHautGamme;
  final double basePopulaire;
  final double baseChinoise;
  final double baseDefaut;

  // Coefficients d'âge
  final double coefAge0a1;
  final double coefAge1a3;
  final double coefAge3a5;
  final double coefAge5a10;
  final double coefAge10a15;
  final double coefAge15Plus;

  // Coefficients de puissance
  final double coefCv0a4;
  final double coefCv4a6;
  final double coefCv6a8;
  final double coefCv8a10;
  final double coefCv10a13;
  final double coefCv13Plus;

  // Prime minimum
  final double primeMinimum;

  final DateTime updatedAt;
  final String updatedBy;

  TarifConfigModel({
    this.id = 'assurance_auto',
    required this.basePremium,
    required this.baseHautGamme,
    required this.basePopulaire,
    required this.baseChinoise,
    required this.baseDefaut,
    required this.coefAge0a1,
    required this.coefAge1a3,
    required this.coefAge3a5,
    required this.coefAge5a10,
    required this.coefAge10a15,
    required this.coefAge15Plus,
    required this.coefCv0a4,
    required this.coefCv4a6,
    required this.coefCv6a8,
    required this.coefCv8a10,
    required this.coefCv10a13,
    required this.coefCv13Plus,
    required this.primeMinimum,
    required this.updatedAt,
    required this.updatedBy,
  });

  /// Valeurs par défaut (identiques au code actuel)
  factory TarifConfigModel.defaut() {
    return TarifConfigModel(
      basePremium: 15000,
      baseHautGamme: 10000,
      basePopulaire: 8000,
      baseChinoise: 7000,
      baseDefaut: 8000,
      coefAge0a1: 1.30,
      coefAge1a3: 1.20,
      coefAge3a5: 1.10,
      coefAge5a10: 1.00,
      coefAge10a15: 0.90,
      coefAge15Plus: 0.80,
      coefCv0a4: 0.85,
      coefCv4a6: 1.00,
      coefCv6a8: 1.15,
      coefCv8a10: 1.30,
      coefCv10a13: 1.50,
      coefCv13Plus: 1.80,
      primeMinimum: 5000,
      updatedAt: DateTime.now(),
      updatedBy: 'system',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'basePremium': basePremium,
      'baseHautGamme': baseHautGamme,
      'basePopulaire': basePopulaire,
      'baseChinoise': baseChinoise,
      'baseDefaut': baseDefaut,
      'coefAge0a1': coefAge0a1,
      'coefAge1a3': coefAge1a3,
      'coefAge3a5': coefAge3a5,
      'coefAge5a10': coefAge5a10,
      'coefAge10a15': coefAge10a15,
      'coefAge15Plus': coefAge15Plus,
      'coefCv0a4': coefCv0a4,
      'coefCv4a6': coefCv4a6,
      'coefCv6a8': coefCv6a8,
      'coefCv8a10': coefCv8a10,
      'coefCv10a13': coefCv10a13,
      'coefCv13Plus': coefCv13Plus,
      'primeMinimum': primeMinimum,
      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
    };
  }

  factory TarifConfigModel.fromMap(Map<String, dynamic> map) {
    return TarifConfigModel(
      id: 'assurance_auto',
      basePremium: (map['basePremium'] as num?)?.toDouble() ?? 15000,
      baseHautGamme: (map['baseHautGamme'] as num?)?.toDouble() ?? 10000,
      basePopulaire: (map['basePopulaire'] as num?)?.toDouble() ?? 8000,
      baseChinoise: (map['baseChinoise'] as num?)?.toDouble() ?? 7000,
      baseDefaut: (map['baseDefaut'] as num?)?.toDouble() ?? 8000,
      coefAge0a1: (map['coefAge0a1'] as num?)?.toDouble() ?? 1.30,
      coefAge1a3: (map['coefAge1a3'] as num?)?.toDouble() ?? 1.20,
      coefAge3a5: (map['coefAge3a5'] as num?)?.toDouble() ?? 1.10,
      coefAge5a10: (map['coefAge5a10'] as num?)?.toDouble() ?? 1.00,
      coefAge10a15: (map['coefAge10a15'] as num?)?.toDouble() ?? 0.90,
      coefAge15Plus: (map['coefAge15Plus'] as num?)?.toDouble() ?? 0.80,
      coefCv0a4: (map['coefCv0a4'] as num?)?.toDouble() ?? 0.85,
      coefCv4a6: (map['coefCv4a6'] as num?)?.toDouble() ?? 1.00,
      coefCv6a8: (map['coefCv6a8'] as num?)?.toDouble() ?? 1.15,
      coefCv8a10: (map['coefCv8a10'] as num?)?.toDouble() ?? 1.30,
      coefCv10a13: (map['coefCv10a13'] as num?)?.toDouble() ?? 1.50,
      coefCv13Plus: (map['coefCv13Plus'] as num?)?.toDouble() ?? 1.80,
      primeMinimum: (map['primeMinimum'] as num?)?.toDouble() ?? 5000,
      updatedAt: map['updatedAt']?.toDate() ?? DateTime.now(),
      updatedBy: map['updatedBy'] ?? 'system',
    );
  }

  TarifConfigModel copyWith({
    double? basePremium,
    double? baseHautGamme,
    double? basePopulaire,
    double? baseChinoise,
    double? baseDefaut,
    double? coefAge0a1,
    double? coefAge1a3,
    double? coefAge3a5,
    double? coefAge5a10,
    double? coefAge10a15,
    double? coefAge15Plus,
    double? coefCv0a4,
    double? coefCv4a6,
    double? coefCv6a8,
    double? coefCv8a10,
    double? coefCv10a13,
    double? coefCv13Plus,
    double? primeMinimum,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return TarifConfigModel(
      basePremium: basePremium ?? this.basePremium,
      baseHautGamme: baseHautGamme ?? this.baseHautGamme,
      basePopulaire: basePopulaire ?? this.basePopulaire,
      baseChinoise: baseChinoise ?? this.baseChinoise,
      baseDefaut: baseDefaut ?? this.baseDefaut,
      coefAge0a1: coefAge0a1 ?? this.coefAge0a1,
      coefAge1a3: coefAge1a3 ?? this.coefAge1a3,
      coefAge3a5: coefAge3a5 ?? this.coefAge3a5,
      coefAge5a10: coefAge5a10 ?? this.coefAge5a10,
      coefAge10a15: coefAge10a15 ?? this.coefAge10a15,
      coefAge15Plus: coefAge15Plus ?? this.coefAge15Plus,
      coefCv0a4: coefCv0a4 ?? this.coefCv0a4,
      coefCv4a6: coefCv4a6 ?? this.coefCv4a6,
      coefCv6a8: coefCv6a8 ?? this.coefCv6a8,
      coefCv8a10: coefCv8a10 ?? this.coefCv8a10,
      coefCv10a13: coefCv10a13 ?? this.coefCv10a13,
      coefCv13Plus: coefCv13Plus ?? this.coefCv13Plus,
      primeMinimum: primeMinimum ?? this.primeMinimum,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
