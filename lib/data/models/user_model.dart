// lib/data/models/user_model.dart

/// Modèle utilisateur pour Firestore
class UserModel {
  final String id; // Firebase UID
  final String phoneNumber;
  final String prenom;
  final String monnaie;
  final String codePays;
  final bool hasAccessVie;
  final bool onboardingVu;
  final bool notificationsActivees;
  final String role; // 'user' | 'admin'
  final DateTime? createdAt;
  final DateTime? dernierActive;

  UserModel({
    required this.id,
    required this.phoneNumber,
    required this.prenom,
    this.monnaie = 'FCFA',
    this.codePays = 'CI',
    this.hasAccessVie = false,
    this.onboardingVu = false,
    this.notificationsActivees = true,
    this.role = 'user',
    this.createdAt,
    this.dernierActive,
  });

  bool get isAdmin => role == 'admin';

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      phoneNumber: map['phoneNumber'] ?? '',
      prenom: map['prenom'] ?? '',
      monnaie: map['monnaie'] ?? 'FCFA',
      codePays: map['codePays'] ?? 'CI',
      hasAccessVie: map['hasAccessVie'] ?? false,
      onboardingVu: map['onboardingVu'] ?? false,
      notificationsActivees: map['notificationsActivees'] ?? true,
      role: (map['role'] as String?) ?? 'user',
      createdAt: map['createdAt']?.toDate(),
      dernierActive: map['dernierActive']?.toDate(),
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
      'role': role,
      'createdAt': createdAt,
      'dernierActive': dernierActive,
    };
  }

  UserModel copyWith({
    String? id,
    String? phoneNumber,
    String? prenom,
    String? monnaie,
    String? codePays,
    bool? hasAccessVie,
    bool? onboardingVu,
    bool? notificationsActivees,
    String? role,
    DateTime? createdAt,
    DateTime? dernierActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      prenom: prenom ?? this.prenom,
      monnaie: monnaie ?? this.monnaie,
      codePays: codePays ?? this.codePays,
      hasAccessVie: hasAccessVie ?? this.hasAccessVie,
      onboardingVu: onboardingVu ?? this.onboardingVu,
      notificationsActivees:
          notificationsActivees ?? this.notificationsActivees,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      dernierActive: dernierActive ?? this.dernierActive,
    );
  }
}
