// lib/data/models/souscription_model.dart

class SouscriptionModel {
  final String id;
  final String reference;
  final String userId;
  final String produitNom;
  final double montant;
  final String statut;
  final String clientNom;
  final String clientPrenom;
  final String clientEmail;
  final String clientPhone;
  final DateTime dateCreation;
  final DateTime updatedAt;

  SouscriptionModel({
    required this.id,
    required this.reference,
    required this.userId,
    required this.produitNom,
    required this.montant,
    required this.statut,
    required this.clientNom,
    required this.clientPrenom,
    required this.clientEmail,
    required this.clientPhone,
    required this.dateCreation,
    required this.updatedAt,
  });

  bool get estEnCours => statut == 'en_cours';
  bool get estPayee => statut == 'payee';
  bool get estAnnulee => statut == 'annulee';

  Map<String, dynamic> toMap() {
    return {
      'reference': reference,
      'userId': userId,
      'produitNom': produitNom,
      'montant': montant,
      'statut': statut,
      'clientNom': clientNom,
      'clientPrenom': clientPrenom,
      'clientEmail': clientEmail,
      'clientPhone': clientPhone,
      'dateCreation': dateCreation,
      'updatedAt': updatedAt,
    };
  }

  factory SouscriptionModel.fromMap(Map<String, dynamic> map, String id) {
    return SouscriptionModel(
      id: id,
      reference: map['reference'] ?? '',
      userId: map['userId'] ?? '',
      produitNom: map['produitNom'] ?? '',
      montant: (map['montant'] as num?)?.toDouble() ?? 0,
      statut: map['statut'] ?? 'en_cours',
      clientNom: map['clientNom'] ?? '',
      clientPrenom: map['clientPrenom'] ?? '',
      clientEmail: map['clientEmail'] ?? '',
      clientPhone: map['clientPhone'] ?? '',
      dateCreation: map['dateCreation']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  SouscriptionModel copyWith({
    String? id,
    String? reference,
    String? userId,
    String? produitNom,
    double? montant,
    String? statut,
    String? clientNom,
    String? clientPrenom,
    String? clientEmail,
    String? clientPhone,
    DateTime? dateCreation,
    DateTime? updatedAt,
  }) {
    return SouscriptionModel(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      userId: userId ?? this.userId,
      produitNom: produitNom ?? this.produitNom,
      montant: montant ?? this.montant,
      statut: statut ?? this.statut,
      clientNom: clientNom ?? this.clientNom,
      clientPrenom: clientPrenom ?? this.clientPrenom,
      clientEmail: clientEmail ?? this.clientEmail,
      clientPhone: clientPhone ?? this.clientPhone,
      dateCreation: dateCreation ?? this.dateCreation,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
