// lib/data/models/epargne_programmee_model.dart

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

  Map<String, dynamic> toMap() => {
    'id': id,
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

  factory EpargneProgrammeeModel.fromMap(Map<String, dynamic> map) => EpargneProgrammeeModel(
    id: map['id'],
    uuid: map['uuid'],
    utilisateurId: map['utilisateurId'],
    titre: map['titre'],
    montantObjectif: map['montantObjectif']?.toDouble() ?? 0,
    frequence: map['frequence'] ?? 'mois',
    duree: map['duree'] ?? 1,
    montantParDepot: map['montantParDepot']?.toDouble() ?? 0,
    portefeuilleId: map['portefeuilleId'],
    dateCreation: DateTime.parse(map['dateCreation']),
    dateFinPrevue: DateTime.parse(map['dateFinPrevue']),
    montantEpargne: map['montantEpargne']?.toDouble() ?? 0,
    verrouille: map['verrouille'] ?? false,
    codeDeverrouillage: map['codeDeverrouillage'],
    termine: map['termine'] ?? false,
  );

  EpargneProgrammeeModel copyWith({
    double? montantEpargne,
    bool? verrouille,
    bool? termine,
  }) => EpargneProgrammeeModel(
    id: id,
    uuid: uuid,
    utilisateurId: utilisateurId,
    titre: titre,
    montantObjectif: montantObjectif,
    frequence: frequence,
    duree: duree,
    montantParDepot: montantParDepot,
    portefeuilleId: portefeuilleId,
    dateCreation: dateCreation,
    dateFinPrevue: dateFinPrevue,
    montantEpargne: montantEpargne ?? this.montantEpargne,
    verrouille: verrouille ?? this.verrouille,
    codeDeverrouillage: codeDeverrouillage,
    termine: termine ?? this.termine,
  );
}