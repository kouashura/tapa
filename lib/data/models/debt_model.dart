// lib/data/models/debt_model.dart

/// Remboursement d'une dette
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

  Map<String, dynamic> toMap() {
    return {
      'montant': montant,
      'date': date,
      'walletId': walletId,
      'note': note,
    };
  }

  factory RemboursementModel.fromMap(Map<String, dynamic> map, String id) {
    return RemboursementModel(
      id: id,
      montant: (map['montant'] as num?)?.toDouble() ?? 0,
      date: map['date']?.toDate() ?? DateTime.now(),
      walletId: map['walletId'] ?? '',
      note: map['note'],
    );
  }

  RemboursementModel copyWith({
    String? id,
    double? montant,
    DateTime? date,
    String? walletId,
    String? note,
  }) {
    return RemboursementModel(
      id: id ?? this.id,
      montant: montant ?? this.montant,
      date: date ?? this.date,
      walletId: walletId ?? this.walletId,
      note: note ?? this.note,
    );
  }
}

/// Modèle dette/créance
class DetteModel {
  final String id;
  final String uid;
  final String type; // 'dette' ou 'creance'
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
    required this.uid,
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

  double get progression => montantTotal > 0
      ? (montantRembourse / montantTotal).clamp(0.0, 1.0)
      : 0.0;

  bool get estSolde => montantRestant <= 0;

  bool get enAttente => !estSolde && remboursements.isEmpty;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'type': type,
      'montantTotal': montantTotal,
      'montantRembourse': montantRembourse,
      'modalite': modalite,
      'periodesMois': periodesMois,
      'dateDebut': dateDebut,
      'dateFin': dateFin,
      'dateCreation': dateCreation,
    };
  }

  factory DetteModel.fromMap(Map<String, dynamic> map, String id) {
    return DetteModel(
      id: id,
      uid: map['uid'] ?? '',
      type: map['type'] ?? '',
      montantTotal: (map['montantTotal'] as num?)?.toDouble() ?? 0,
      montantRembourse: (map['montantRembourse'] as num?)?.toDouble() ?? 0,
      modalite: map['modalite'] ?? '',
      periodesMois: map['periodesMois'] ?? 1,
      dateDebut: map['dateDebut']?.toDate() ?? DateTime.now(),
      dateFin: map['dateFin']?.toDate() ?? DateTime.now(),
      dateCreation: map['dateCreation']?.toDate() ?? DateTime.now(),
    );
  }

  DetteModel copyWith({
    String? id,
    String? uid,
    String? type,
    double? montantTotal,
    double? montantRembourse,
    String? modalite,
    int? periodesMois,
    DateTime? dateDebut,
    DateTime? dateFin,
    DateTime? dateCreation,
    List<RemboursementModel>? remboursements,
  }) {
    return DetteModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      type: type ?? this.type,
      montantTotal: montantTotal ?? this.montantTotal,
      montantRembourse: montantRembourse ?? this.montantRembourse,
      modalite: modalite ?? this.modalite,
      periodesMois: periodesMois ?? this.periodesMois,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      dateCreation: dateCreation ?? this.dateCreation,
      remboursements: remboursements ?? this.remboursements,
    );
  }
}