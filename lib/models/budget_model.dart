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

  double get soldePrevu => totalRevenusPrevu - totalDepensesPrevu;

  String get moisLabel {
    const ms = ['', 'Janvier', 'Fevrier', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Aout', 'Septembre', 'Octobre', 'Novembre', 'Decembre'];
    return '${ms[mois]} $annee';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'mois': mois,
    'annee': annee,
    'lignes': lignes.map((l) => l.toMap()).toList(),
  };

  factory BudgetMensuel.fromMap(Map<String, dynamic> map) => BudgetMensuel(
    id: map['id'],
    mois: map['mois'],
    annee: map['annee'],
    lignes: (map['lignes'] as List)
        .map((l) => BudgetLigne.fromMap(l))
        .toList(),
  );
}

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

  Map<String, dynamic> toMap() => {
    'id': id,
    'categorieId': categorieId,
    'categorieLabel': categorieLabel,
    'categorieEmoji': categorieEmoji,
    'montantPrevu': montantPrevu,
    'isRevenu': isRevenu,
  };

  factory BudgetLigne.fromMap(Map<String, dynamic> map) => BudgetLigne(
    id: map['id'],
    categorieId: map['categorieId'],
    categorieLabel: map['categorieLabel'],
    categorieEmoji: map['categorieEmoji'] ?? '📌',
    montantPrevu: (map['montantPrevu'] as num?)?.toDouble() ?? 0,
    isRevenu: map['isRevenu'] ?? false,
  );
}