class DetteModel {
  final String id;
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
    required this.type,
    required this.montantTotal,
    required this.montantRembourse,
    required this.modalite,
    required this.periodesMois,
    required this.dateDebut,
    required this.dateFin,
    required this.dateCreation,
    required this.remboursements,
  });

  double get montantRestant => montantTotal - montantRembourse;
  double get progression => montantTotal > 0
      ? (montantRembourse / montantTotal).clamp(0.0, 1.0) : 0.0;
  bool get estSolde => montantRembourse >= montantTotal;

  int get moisRestants {
    if (estSolde) return 0;
    if (periodesMois <= 0 || montantTotal <= 0) return 0;
    // Montant mensuel prevu
    final montantMensuel = montantTotal / periodesMois;
    if (montantMensuel <= 0) return 0;
    // Mois restants bases sur ce qui reste a payer
    return (montantRestant / montantMensuel).ceil().clamp(0, 999);
  }

  bool get enAttente {
    if (estSolde) return false;
    final now = DateTime.now();
    final diff = now.difference(dateCreation);
    if (diff.inDays < 30) return false;
    if (remboursements.isEmpty) return true;
    final dernierRemb = remboursements.last.date;
    return now.difference(dernierRemb).inDays > 30;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'montantTotal': montantTotal,
    'montantRembourse': montantRembourse,
    'modalite': modalite,
    'periodesMois': periodesMois,
    'dateDebut': dateDebut.toIso8601String(),
    'dateFin': dateFin.toIso8601String(),
    'dateCreation': dateCreation.toIso8601String(),
    'remboursements': remboursements.map((r) => r.toMap()).toList(),
  };

  factory DetteModel.fromMap(Map<String, dynamic> m) => DetteModel(
    id: m['id'],
    type: m['type'],
    montantTotal: (m['montantTotal'] as num).toDouble(),
    montantRembourse: (m['montantRembourse'] as num).toDouble(),
    modalite: m['modalite'],
    periodesMois: m['periodesMois'],
    dateDebut: DateTime.parse(m['dateDebut']),
    dateFin: DateTime.parse(m['dateFin']),
    dateCreation: DateTime.parse(m['dateCreation']),
    remboursements: (m['remboursements'] as List)
        .map((r) => RemboursementModel.fromMap(
            Map<String, dynamic>.from(r)))
        .toList(),
  );
}

class RemboursementModel {
  final String id;
  final double montant;
  final DateTime date;
  final String walletId;
  final String note;

  RemboursementModel({
    required this.id,
    required this.montant,
    required this.date,
    required this.walletId,
    required this.note,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'montant': montant,
    'date': date.toIso8601String(),
    'walletId': walletId,
    'note': note,
  };

  factory RemboursementModel.fromMap(
      Map<String, dynamic> m) => RemboursementModel(
    id: m['id'],
    montant: (m['montant'] as num).toDouble(),
    date: DateTime.parse(m['date']),
    walletId: m['walletId'],
    note: m['note'] ?? '',
  );
}
