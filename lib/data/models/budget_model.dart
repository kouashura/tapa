// lib/data/models/budget_model.dart

/// Ligne de budget
class BudgetLigne {
  final String id;
  final String categorieId;
  final String categorieLabel;
  final String categorieEmoji;
  final double montantPrevu;
  final bool isRevenu;

  BudgetLigne({
    required this.id,
    required this.categorieId,
    required this.categorieLabel,
    required this.categorieEmoji,
    required this.montantPrevu,
    required this.isRevenu,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categorieId': categorieId,
      'categorieLabel': categorieLabel,
      'categorieEmoji': categorieEmoji,
      'montantPrevu': montantPrevu,
      'isRevenu': isRevenu,
    };
  }

  factory BudgetLigne.fromMap(Map<String, dynamic> map) {
    return BudgetLigne(
      id: map['id'] ?? '',
      categorieId: map['categorieId'] ?? '',
      categorieLabel: map['categorieLabel'] ?? '',
      categorieEmoji: map['categorieEmoji'] ?? '📌',
      montantPrevu: (map['montantPrevu'] as num?)?.toDouble() ?? 0,
      isRevenu: map['isRevenu'] ?? false,
    );
  }

  BudgetLigne copyWith({
    String? id,
    String? categorieId,
    String? categorieLabel,
    String? categorieEmoji,
    double? montantPrevu,
    bool? isRevenu,
  }) {
    return BudgetLigne(
      id: id ?? this.id,
      categorieId: categorieId ?? this.categorieId,
      categorieLabel: categorieLabel ?? this.categorieLabel,
      categorieEmoji: categorieEmoji ?? this.categorieEmoji,
      montantPrevu: montantPrevu ?? this.montantPrevu,
      isRevenu: isRevenu ?? this.isRevenu,
    );
  }
}

/// Budget mensuel
class BudgetMensuel {
  final String id;
  final int mois;
  final int annee;
  final List<BudgetLigne> lignes;

  BudgetMensuel({
    required this.id,
    required this.mois,
    required this.annee,
    required this.lignes,
  });

  List<BudgetLigne> get revenus => lignes.where((l) => l.isRevenu).toList();
  List<BudgetLigne> get depenses => lignes.where((l) => !l.isRevenu).toList();

  double get totalRevenusPrevu =>
      revenus.fold(0.0, (sum, l) => sum + l.montantPrevu);

  double get totalDepensesPrevu =>
      depenses.fold(0.0, (sum, l) => sum + l.montantPrevu);

  String get moisLabel {
    const ms = [
      '',
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre'
    ];
    return '${ms[mois]} $annee';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mois': mois,
      'annee': annee,
      'lignes': lignes.map((l) => l.toMap()).toList(),
    };
  }

  factory BudgetMensuel.fromMap(Map<String, dynamic> map) {
    return BudgetMensuel(
      id: map['id'] ?? '',
      mois: map['mois'] ?? 1,
      annee: map['annee'] ?? DateTime.now().year,
      lignes: (map['lignes'] as List?)
              ?.map((l) => BudgetLigne.fromMap(l))
              .toList() ??
          [],
    );
  }

  BudgetMensuel copyWith({
    String? id,
    int? mois,
    int? annee,
    List<BudgetLigne>? lignes,
  }) {
    return BudgetMensuel(
      id: id ?? this.id,
      mois: mois ?? this.mois,
      annee: annee ?? this.annee,
      lignes: lignes ?? this.lignes,
    );
  }
}
