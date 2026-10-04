// lib/data/models/models.dart

// ============================================
// EXPORT DE TOUS LES MODÈLES
// ============================================

export 'user_model.dart';
export 'wallet_model.dart';
export 'transaction_model.dart';
export 'budget_model.dart';
export 'debt_model.dart';
export 'savings_goal_model.dart';
export 'echeance_model.dart';
export 'epargne_programmee_model.dart';
export 'souscription_model.dart';
export 'tarif_config_model.dart';

// ============================================
// APP USER (pour auth_provider)
// ============================================

/// Entité utilisateur pour l'application
class AppUser {
  final String id;
  final String phoneNumber;
  final String prenom;
  final String monnaie;
  final String codePays;
  final bool hasAccessVie;
  final bool onboardingVu;
  final bool notificationsActivees;
  final DateTime? createdAt;
  final DateTime? dernierActive;
  final String email;
  final bool emailVerifie;

  AppUser({
    required this.id,
    required this.phoneNumber,
    required this.prenom,
    this.monnaie = 'FCFA',
    this.codePays = 'CI',
    this.hasAccessVie = false,
    this.onboardingVu = false,
    this.notificationsActivees = true,
    this.createdAt,
    this.dernierActive,
    this.email = '',
    this.emailVerifie = false,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String id) {
    return AppUser(
      id: id,
      phoneNumber: map['phoneNumber'] ?? '',
      prenom: map['prenom'] ?? '',
      monnaie: map['monnaie'] ?? 'FCFA',
      codePays: map['codePays'] ?? 'CI',
      hasAccessVie: map['hasAccessVie'] ?? false,
      onboardingVu: map['onboardingVu'] ?? false,
      notificationsActivees: map['notificationsActivees'] ?? true,
      createdAt: map['createdAt']?.toDate(),
      dernierActive: map['dernierActive']?.toDate(),
      email: map['email'] ?? '',
      emailVerifie: map['emailVerifie'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phoneNumber': phoneNumber,
      'prenom': prenom,
      'monnaie': monnaie,
      'codePays': codePays,
      'hasAccessVie': hasAccessVie,
      'onboardingVu': onboardingVu,
      'notificationsActivees': notificationsActivees,
      'createdAt': createdAt,
      'dernierActive': dernierActive,
      'email': email,
      'emailVerifie': emailVerifie,
    };
  }

  AppUser copyWith({
    String? id,
    String? phoneNumber,
    String? prenom,
    String? monnaie,
    String? codePays,
    bool? hasAccessVie,
    bool? onboardingVu,
    bool? notificationsActivees,
    DateTime? createdAt,
    DateTime? dernierActive,
    String? email,
    bool? emailVerifie,
  }) {
    return AppUser(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      prenom: prenom ?? this.prenom,
      monnaie: monnaie ?? this.monnaie,
      codePays: codePays ?? this.codePays,
      hasAccessVie: hasAccessVie ?? this.hasAccessVie,
      onboardingVu: onboardingVu ?? this.onboardingVu,
      notificationsActivees: notificationsActivees ?? this.notificationsActivees,
      createdAt: createdAt ?? this.createdAt,
      dernierActive: dernierActive ?? this.dernierActive,
      email: email ?? this.email,
      emailVerifie: emailVerifie ?? this.emailVerifie,
    );
  }
}

// ============================================
// CATEGORIE MODEL (Firestore compatible)
// ============================================

/// Modèle catégorie pour Firestore
class CategorieModel {
  final String id;
  final String uid;
  final String categorieId;
  final String label;
  final String emoji;
  final String type; // 'revenu' ou 'depense'
  final bool isDefault;
  final DateTime createdAt;

  CategorieModel({
    required this.id,
    required this.uid,
    required this.categorieId,
    required this.label,
    required this.emoji,
    required this.type,
    required this.isDefault,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'categorieId': categorieId,
      'label': label,
      'emoji': emoji,
      'type': type,
      'isDefault': isDefault,
      'createdAt': createdAt,
    };
  }

  factory CategorieModel.fromMap(Map<String, dynamic> map, String id) {
    return CategorieModel(
      id: id,
      uid: map['uid'] ?? '',
      categorieId: map['categorieId'] ?? '',
      label: map['label'] ?? '',
      emoji: map['emoji'] ?? '📌',
      type: map['type'] ?? 'depense',
      isDefault: map['isDefault'] ?? false,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  CategorieModel copyWith({
    String? id,
    String? uid,
    String? categorieId,
    String? label,
    String? emoji,
    String? type,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return CategorieModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      categorieId: categorieId ?? this.categorieId,
      label: label ?? this.label,
      emoji: emoji ?? this.emoji,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}