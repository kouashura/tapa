class WalletModel {
  final String id;
  final String uid;
  final String nom;
  final String emoji;
  final String type;
  final double solde;
  final String monnaie;
  final String description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WalletModel({
    required this.id,
    required this.uid,
    required this.nom,
    required this.emoji,
    required this.type,
    required this.solde,
    required this.monnaie,
    this.description = '',
    this.createdAt,
    this.updatedAt,
  });

  factory WalletModel.fromMap(Map<String, dynamic> map) {
    return WalletModel(
      id: map['id'] ?? '',
      uid: map['uid'] ?? '',
      nom: map['nom'] ?? '',
      emoji: map['emoji'] ?? '💵',
      type: map['type'] ?? 'autre',
      solde: (map['solde'] as num?)?.toDouble() ?? 0,
      monnaie: map['monnaie'] ?? 'FCFA',
      description: map['description'] ?? '',
      createdAt: map['createdAt']?.toDate(),
      updatedAt: map['updatedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nom': nom,
      'emoji': emoji,
      'type': type,
      'solde': solde,
      'monnaie': monnaie,
      'description': description,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  WalletModel copyWith({
    String? id,
    String? uid,
    String? nom,
    String? emoji,
    String? type,
    double? solde,
    String? monnaie,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WalletModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      nom: nom ?? this.nom,
      emoji: emoji ?? this.emoji,
      type: type ?? this.type,
      solde: solde ?? this.solde,
      monnaie: monnaie ?? this.monnaie,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
