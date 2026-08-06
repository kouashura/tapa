export 'dette_model.dart';
export 'budget_model.dart';
export 'echeance_model.dart';

class UserModel {
  final int? id;
  final String uuid;
  final String prenom;
  final String telephone;
  final String indicatif;
  final String codePays;
  final String monnaie;
  final String pinCode;
  final bool hasAccesVie;
  final DateTime dateInscription;

  UserModel({
    this.id,
    required this.uuid,
    required this.prenom,
    required this.telephone,
    required this.indicatif,
    required this.codePays,
    required this.monnaie,
    required this.pinCode,
    required this.hasAccesVie,
    required this.dateInscription,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'uuid': uuid,
    'prenom': prenom,
    'telephone': telephone,
    'indicatif': indicatif,
    'codePays': codePays,
    'monnaie': monnaie,
    'pinCode': pinCode,
    'hasAccesVie': hasAccesVie,
    'dateInscription': dateInscription.toIso8601String(),
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    uuid: json['uuid'] ?? '',
    prenom: json['prenom'] ?? '',
    telephone: json['telephone'] ?? '',
    indicatif: json['indicatif'] ?? '+225',
    codePays: json['codePays'] ?? 'CI',
    monnaie: json['monnaie'] ?? 'FCFA',
    pinCode: json['pinCode'] ?? '',
    hasAccesVie: json['hasAccesVie'] ?? false,
    dateInscription: json['dateInscription'] != null
        ? DateTime.parse(json['dateInscription'])
        : DateTime.now(),
  );

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    id: map['id'],
    uuid: map['uuid'] ?? '',
    prenom: map['prenom'] ?? '',
    telephone: map['telephone'] ?? '',
    indicatif: map['indicatif'] ?? '+225',
    codePays: map['codePays'] ?? 'CI',
    monnaie: map['monnaie'] ?? 'FCFA',
    pinCode: map['pinCode'] ?? '',
    hasAccesVie: map['hasAccesVie'] ?? false,
    dateInscription: map['dateInscription'] != null
        ? DateTime.parse(map['dateInscription'])
        : DateTime.now(),
  );
}

class WalletModel {
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

  WalletModel({
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

  factory WalletModel.fromMap(Map<String, dynamic> map) => WalletModel(
    id: map['id'],
    uuid: map['uuid'] ?? '',
    utilisateurId: map['utilisateurId'] ?? 0,
    nom: map['nom'] ?? '',
    type: map['type'] ?? 'compte',
    emoji: map['emoji'] ?? '💰',
    solde: (map['solde'] as num?)?.toDouble() ?? 0,
    seuilAlerte: (map['seuilAlerte'] as num?)?.toDouble() ?? 5000,
    updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    createdAt: map['createdAt'] != null
        ? DateTime.parse(map['createdAt'])
        : DateTime.now(),
  );

  WalletModel copyWith({
    String? nom,
    String? emoji,
    double? solde,
    double? seuilAlerte,
    DateTime? updatedAt,
  }) => WalletModel(
    id: id,
    uuid: uuid,
    utilisateurId: utilisateurId,
    nom: nom ?? this.nom,
    type: type,
    emoji: emoji ?? this.emoji,
    solde: solde ?? this.solde,
    seuilAlerte: seuilAlerte ?? this.seuilAlerte,
    updatedAt: updatedAt ?? this.updatedAt,
    createdAt: createdAt,
  );
}

enum TransactionType {
  revenu,
  depense,
  transfert
}

class TransactionModel {
  final int? id;
  final String uuid;
  final int utilisateurId;
  final int portefeuilleId;
  final int? portefeuilleDestId;
  final double montant;
  final TransactionType type;
  final String categorieId;
  final String categorieLabel;
  final String categorieEmoji;
  final String? note;
  final DateTime dateTransaction;
  final DateTime createdAt;

  TransactionModel({
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

  Map<String, dynamic> toMap() => {
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
    utilisateurId: json['utilisateurId'] ?? 0,
    portefeuilleId: json['portefeuilleId'] ?? 0,
    portefeuilleDestId: json['portefeuilleDestId'],
    montant: (json['montant'] as num?)?.toDouble() ?? 0,
    type: TransactionType.values.firstWhere(
          (e) => e.name == json['type'],
      orElse: () => TransactionType.depense,
    ),
    categorieId: json['categorieId'] ?? 'autre',
    categorieLabel: json['categorieLabel'] ?? 'Autre',
    categorieEmoji: json['categorieEmoji'] ?? '📝',
    note: json['note'],
    dateTransaction: json['dateTransaction'] != null
        ? DateTime.parse(json['dateTransaction'])
        : DateTime.now(),
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
  );

  factory TransactionModel.fromMap(Map<String, dynamic> map) => TransactionModel(
    id: map['id'],
    uuid: map['uuid'] ?? '',
    utilisateurId: map['utilisateurId'] ?? 0,
    portefeuilleId: map['portefeuilleId'] ?? 0,
    portefeuilleDestId: map['portefeuilleDestId'],
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

class SavingsGoalModel {
  final int? id;
  final String uuid;
  final int utilisateurId;
  final String nom;
  final double montantCible;
  final double montantActuel;
  final DateTime? dateLimite;
  final int portefeuilleId;
  final bool estAtteint;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavingsGoalModel({
    this.id,
    required this.uuid,
    required this.utilisateurId,
    required this.nom,
    required this.montantCible,
    required this.montantActuel,
    this.dateLimite,
    required this.portefeuilleId,
    required this.estAtteint,
    required this.createdAt,
    required this.updatedAt,
  });

  double get progression => montantCible > 0
      ? (montantActuel / montantCible).clamp(0.0, 1.0)
      : 0;
  double get progressionPct => progression * 100;
  double get resteAEpargner =>
      (montantCible - montantActuel).clamp(0.0, double.infinity);
  int get joursRestants =>
      dateLimite?.difference(DateTime.now()).inDays ?? 0;

  double get montantParSemaine {
    final semaines = joursRestants / 7;
    return semaines > 0 ? resteAEpargner / semaines : resteAEpargner;
  }

  String get messageMotivation {
    final p = progressionPct;
    if (p >= 100) return 'Objectif atteint !';
    if (p >= 75) return 'Plus que le dernier effort !';
    if (p >= 50) return 'Tu es a mi-chemin, bravo !';
    if (p >= 25) return 'Bon debut ! Continue !';
    return 'C\'est un bon depart !';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uuid': uuid,
    'utilisateurId': utilisateurId,
    'nom': nom,
    'montantCible': montantCible,
    'montantActuel': montantActuel,
    'dateLimite': dateLimite?.toIso8601String(),
    'portefeuilleId': portefeuilleId,
    'estAtteint': estAtteint,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory SavingsGoalModel.fromJson(Map<String, dynamic> json) => SavingsGoalModel(
    id: json['id'],
    uuid: json['uuid'] ?? '',
    utilisateurId: json['utilisateurId'] ?? 0,
    nom: json['nom'] ?? '',
    montantCible: (json['montantCible'] as num?)?.toDouble() ?? 0,
    montantActuel: (json['montantActuel'] as num?)?.toDouble() ?? 0,
    dateLimite: json['dateLimite'] != null ? DateTime.parse(json['dateLimite']) : null,
    portefeuilleId: json['portefeuilleId'] ?? 0,
    estAtteint: json['estAtteint'] ?? false,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'])
        : DateTime.now(),
  );

  SavingsGoalModel copyWith({
    double? montantActuel,
    bool? estAtteint,
    DateTime? updatedAt,
  }) => SavingsGoalModel(
    id: id,
    uuid: uuid,
    utilisateurId: utilisateurId,
    nom: nom,
    montantCible: montantCible,
    montantActuel: montantActuel ?? this.montantActuel,
    dateLimite: dateLimite,
    portefeuilleId: portefeuilleId,
    estAtteint: estAtteint ?? this.estAtteint,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class CategorieModel {
  final int? id;
  final int utilisateurId;
  final String categorieId;
  final String label;
  final String emoji;
  final String type;
  final String? typeBudget;
  final bool isDefault;
  final DateTime createdAt;

  CategorieModel({
    this.id,
    required this.utilisateurId,
    required this.categorieId,
    required this.label,
    required this.emoji,
    required this.type,
    this.typeBudget,
    required this.isDefault,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'utilisateurId': utilisateurId,
    'categorieId': categorieId,
    'label': label,
    'emoji': emoji,
    'type': type,
    'typeBudget': typeBudget,
    'isDefault': isDefault,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CategorieModel.fromJson(Map<String, dynamic> json) => CategorieModel(
    id: json['id'],
    utilisateurId: json['utilisateurId'] ?? 0,
    categorieId: json['categorieId'] ?? '',
    label: json['label'] ?? '',
    emoji: json['emoji'] ?? '📌',
    type: json['type'] ?? 'depense',
    typeBudget: json['typeBudget'],
    isDefault: json['isDefault'] ?? false,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
  );
}

class RemboursementModel {
  final String id;
  final double montant;
  final DateTime date;
  final String walletId;
  final String? note;

  RemboursementModel({
    required this.id,
    required this.montant,
    required this.date,
    required this.walletId,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'montant': montant,
    'date': date.toIso8601String(),
    'walletId': walletId,
    'note': note,
  };

  factory RemboursementModel.fromJson(Map<String, dynamic> json) => RemboursementModel(
    id: json['id'],
    montant: (json['montant'] as num?)?.toDouble() ?? 0,
    date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    walletId: json['walletId'] ?? '',
    note: json['note'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'montant': montant,
    'date': date.toIso8601String(),
    'walletId': walletId,
    'note': note,
  };

  factory RemboursementModel.fromMap(Map<String, dynamic> map) => RemboursementModel(
    id: map['id'],
    montant: (map['montant'] as num?)?.toDouble() ?? 0,
    date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
    walletId: map['walletId'] ?? '',
    note: map['note'],
  );
}

class DetteModel {
  final String id;
  final String uuid;
  final int utilisateurId;
  final String type;
  final double montantTotal;
  final double montantRembourse;
  final String modalite;
  final int periodesMois;
  final DateTime dateDebut;
  final DateTime dateFin;
  final DateTime dateCreation;
  final List<RemboursementModel> remboursements;

  DetteModel({
    required this.id,
    required this.uuid,
    required this.utilisateurId,
    required this.type,
    required this.montantTotal,
    required this.montantRembourse,
    required this.modalite,
    required this.periodesMois,
    required this.dateDebut,
    required this.dateFin,
    required this.dateCreation,
    this.remboursements = const [],
  });

  double get montantRestant => montantTotal - montantRembourse;
  double get progression => montantTotal > 0 ? (montantRembourse / montantTotal).clamp(0.0, 1.0) : 0.0;
  bool get estSolde => montantRestant <= 0;
  bool get enAttente => !estSolde && remboursements.isEmpty;

  Map<String, dynamic> toJson() => {
    'id': id,
    'uuid': uuid,
    'utilisateurId': utilisateurId,
    'type': type,
    'montantTotal': montantTotal,
    'montantRembourse': montantRembourse,
    'modalite': modalite,
    'periodesMois': periodesMois,
    'dateDebut': dateDebut.toIso8601String(),
    'dateFin': dateFin.toIso8601String(),
    'dateCreation': dateCreation.toIso8601String(),
  };

  factory DetteModel.fromJson(Map<String, dynamic> json) => DetteModel(
    id: json['id'],
    uuid: json['uuid'] ?? '',
    utilisateurId: json['utilisateurId'] ?? 0,
    type: json['type'] ?? '',
    montantTotal: (json['montantTotal'] as num?)?.toDouble() ?? 0,
    montantRembourse: (json['montantRembourse'] as num?)?.toDouble() ?? 0,
    modalite: json['modalite'],
    periodesMois: json['periodesMois'] ?? 1,
    dateDebut: json['dateDebut'] != null
        ? DateTime.parse(json['dateDebut'])
        : DateTime.now(),
    dateFin: json['dateFin'] != null
        ? DateTime.parse(json['dateFin'])
        : DateTime.now(),
    dateCreation: json['dateCreation'] != null
        ? DateTime.parse(json['dateCreation'])
        : DateTime.now(),
  );
}