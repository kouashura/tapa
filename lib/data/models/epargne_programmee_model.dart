// lib/data/models/epargne_programmee_model.dart

/// Modèle épargne programmée
class EpargneProgrammeeModel {
  final String id;
  final String uuid;
  final int utilisateurId;
  final String titre;
  final double montantObjectif;
  final String frequence; // 'jour', 'semaine', 'mois'
  final int duree;
  final double montantParDepot;
  final int portefeuilleId;
  final DateTime dateCreation;
  final DateTime dateFinPrevue;
  final double montantEpargne;
  final bool verrouille;
  final String? codeDeverrouillage;
  final bool termine;

  EpargneProgrammeeModel({
    required this.id,
    required this.uuid,
    required this.utilisateurId,
    required this.titre,
    required this.montantObjectif,
    required this.frequence,
    required this.duree,
    required this.montantParDepot,
    required this.portefeuilleId,
    required this.dateCreation,
    required this.dateFinPrevue,
    required this.montantEpargne,
    required this.verrouille,
    this.codeDeverrouillage,
    required this.termine,
  });

  int get nombreDepotsTotal => (duree / _frequenceEnJours).ceil();
  int get nombreDepotsEffectues => (montantEpargne / montantParDepot).floor();

  double get pourcentageAtteint => (montantEpargne / montantObjectif * 100).clamp(0, 100);

  int get joursRestants => dateFinPrevue.difference(DateTime.now()).inDays;

  int get _frequenceEnJours {
    switch (frequence) {
      case 'jour': return 1;
      case 'semaine': return 7;
      case 'mois': return 30;
      default: return 1;
    }
  }

  String get descriptionFrequence {
    switch (frequence) {
      case 'jour': return 'Quotidien';
      case 'semaine': return 'Hebdomadaire';
      case 'mois': return 'Mensuel';
      default: return '';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'utilisateurId': utilisateurId,
      'titre': titre,
      'montantObjectif': montantObjectif,
      'frequence': frequence,
      'duree': duree,
      'montantParDepot': montantParDepot,
      'portefeuilleId': portefeuilleId,
      'dateCreation': dateCreation.toIso8601String(),
      'dateFinPrevue': dateFinPrevue.toIso8601String(),
      'montantEpargne': montantEpargne,
      'verrouille': verrouille,
      'codeDeverrouillage': codeDeverrouillage,
      'termine': termine,
    };
  }

  factory EpargneProgrammeeModel.fromMap(Map<String, dynamic> map) {
    return EpargneProgrammeeModel(
      id: map['id'] ?? '',
      uuid: map['uuid'] ?? '',
      utilisateurId: map['utilisateurId'] ?? 0,
      titre: map['titre'] ?? '',
      montantObjectif: map['montantObjectif']?.toDouble() ?? 0,
      frequence: map['frequence'] ?? 'mois',
      duree: map['duree'] ?? 1,
      montantParDepot: map['montantParDepot']?.toDouble() ?? 0,
      portefeuilleId: map['portefeuilleId'] ?? 0,
      dateCreation: map['dateCreation'] != null
          ? DateTime.parse(map['dateCreation'])
          : DateTime.now(),
      dateFinPrevue: map['dateFinPrevue'] != null
          ? DateTime.parse(map['dateFinPrevue'])
          : DateTime.now(),
      montantEpargne: map['montantEpargne']?.toDouble() ?? 0,
      verrouille: map['verrouille'] ?? false,
      codeDeverrouillage: map['codeDeverrouillage'],
      termine: map['termine'] ?? false,
    );
  }

  EpargneProgrammeeModel copyWith({
    String? id,
    String? uuid,
    int? utilisateurId,
    String? titre,
    double? montantObjectif,
    String? frequence,
    int? duree,
    double? montantParDepot,
    int? portefeuilleId,
    DateTime? dateCreation,
    DateTime? dateFinPrevue,
    double? montantEpargne,
    bool? verrouille,
    String? codeDeverrouillage,
    bool? termine,
  }) {
    return EpargneProgrammeeModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      utilisateurId: utilisateurId ?? this.utilisateurId,
      titre: titre ?? this.titre,
      montantObjectif: montantObjectif ?? this.montantObjectif,
      frequence: frequence ?? this.frequence,
      duree: duree ?? this.duree,
      montantParDepot: montantParDepot ?? this.montantParDepot,
      portefeuilleId: portefeuilleId ?? this.portefeuilleId,
      dateCreation: dateCreation ?? this.dateCreation,
      dateFinPrevue: dateFinPrevue ?? this.dateFinPrevue,
      montantEpargne: montantEpargne ?? this.montantEpargne,
      verrouille: verrouille ?? this.verrouille,
      codeDeverrouillage: codeDeverrouillage ?? this.codeDeverrouillage,
      termine: termine ?? this.termine,
    );
  }
}