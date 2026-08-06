class EcheanceModel {
  final String id;
  final String titre;
  final double montant;
  final String type; // 'mensuelle', 'hebdomadaire', 'unique'
  final int? jourDuMois;
  final int? jourDeLaSemaine;
  final DateTime? datePrecise;
  final int rappelAvant; // en heures
  final String emoji;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  EcheanceModel({
    required this.id,
    required this.titre,
    required this.montant,
    required this.type,
    this.jourDuMois,
    this.jourDeLaSemaine,
    this.datePrecise,
    required this.rappelAvant,
    required this.emoji,
    this.active = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  String get descriptionRecurrence {
    switch (type) {
      case 'mensuelle':
        return 'Le ${jourDuMois ?? 1} de chaque mois';
      case 'hebdomadaire':
        final jours = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
        return 'Chaque ${jours[jourDeLaSemaine ?? 1]}';
      default:
        return datePrecise != null
            ? 'Le ${datePrecise!.day}/${datePrecise!.month}/${datePrecise!.year}'
            : 'Date unique';
    }
  }

  String get descriptionRappel {
    if (rappelAvant >= 168) return '1 semaine avant';
    if (rappelAvant >= 72) return '3 jours avant';
    if (rappelAvant >= 48) return '2 jours avant';
    if (rappelAvant >= 24) return '1 jour avant';
    if (rappelAvant >= 10) return '$rappelAvant heures avant';
    if (rappelAvant >= 6) return '6 heures avant';
    if (rappelAvant >= 3) return '3 heures avant';
    return '1 heure avant';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'titre': titre,
    'montant': montant,
    'type': type,
    'jourDuMois': jourDuMois,
    'jourDeLaSemaine': jourDeLaSemaine,
    'datePrecise': datePrecise?.toIso8601String(),
    'rappelAvant': rappelAvant,
    'emoji': emoji,
    'active': active,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory EcheanceModel.fromMap(Map<String, dynamic> map) => EcheanceModel(
    id: map['id'],
    titre: map['titre'],
    montant: map['montant']?.toDouble() ?? 0,
    type: map['type'] ?? 'unique',
    jourDuMois: map['jourDuMois'],
    jourDeLaSemaine: map['jourDeLaSemaine'],
    datePrecise: map['datePrecise'] != null
        ? DateTime.parse(map['datePrecise'])
        : null,
    rappelAvant: map['rappelAvant'] ?? 120,
    emoji: map['emoji'] ?? '⏰',
    active: map['active'] ?? true,
    createdAt: map['createdAt'] != null
        ? DateTime.parse(map['createdAt'])
        : DateTime.now(),
    updatedAt: map['updatedAt'] != null
        ? DateTime.parse(map['updatedAt'])
        : DateTime.now(),
  );
}