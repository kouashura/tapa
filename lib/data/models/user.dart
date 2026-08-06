// lib/data/models/user.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final String id;
  final String uid;
  final String prenom;
  final String telephone;
  final String indicatif;
  final String codePays;
  final String monnaie;
  final String pinCode;
  final bool hasAccesVie;
  final DateTime dateInscription;
  final bool onboardingVu;
  final bool notificationsActivees;
  final DateTime? dernierConnexion;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? cleActivee;

  const AppUser({
    required this.id,
    required this.uid,
    required this.prenom,
    required this.telephone,
    required this.indicatif,
    required this.codePays,
    required this.monnaie,
    this.pinCode = '',
    this.hasAccesVie = false,
    required this.dateInscription,
    this.onboardingVu = false,
    this.notificationsActivees = true,
    this.dernierConnexion,
    this.createdAt,
    this.updatedAt,
    this.cleActivee,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      uid: data['uid'] ?? doc.id,
      prenom: data['prenom'] ?? '',
      telephone: data['telephone'] ?? '',
      indicatif: data['indicatif'] ?? '+225',
      codePays: data['codePays'] ?? 'CI',
      monnaie: data['monnaie'] ?? 'FCFA',
      pinCode: data['pinCode'] ?? '',
      hasAccesVie: data['hasAccesVie'] ?? false,
      dateInscription: data['dateInscription'] != null
          ? DateTime.parse(data['dateInscription'])
          : DateTime.now(),
      onboardingVu: data['onboardingVu'] ?? false,
      notificationsActivees: data['notificationsActivees'] ?? true,
      dernierConnexion: data['dernierConnexion'] != null
          ? DateTime.parse(data['dernierConnexion'])
          : null,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : null,
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'])
          : null,
      cleActivee: data['cleActivee'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'prenom': prenom,
    'telephone': telephone,
    'indicatif': indicatif,
    'codePays': codePays,
    'monnaie': monnaie,
    'pinCode': pinCode,
    'hasAccesVie': hasAccesVie,
    'dateInscription': dateInscription.toIso8601String(),
    'onboardingVu': onboardingVu,
    'notificationsActivees': notificationsActivees,
    'dernierConnexion': dernierConnexion?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'cleActivee': cleActivee,
  };

  @override
  List<Object?> get props => [
    id,
    uid,
    prenom,
    telephone,
    indicatif,
    codePays,
    monnaie,
    pinCode,
    hasAccesVie,
    dateInscription,
    onboardingVu,
    notificationsActivees,
    dernierConnexion,
    createdAt,
    updatedAt,
    cleActivee,
  ];

  AppUser copyWith({
    String? id,
    String? uid,
    String? prenom,
    String? telephone,
    String? indicatif,
    String? codePays,
    String? monnaie,
    String? pinCode,
    bool? hasAccesVie,
    DateTime? dateInscription,
    bool? onboardingVu,
    bool? notificationsActivees,
    DateTime? dernierConnexion,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? cleActivee,
  }) {
    return AppUser(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      prenom: prenom ?? this.prenom,
      telephone: telephone ?? this.telephone,
      indicatif: indicatif ?? this.indicatif,
      codePays: codePays ?? this.codePays,
      monnaie: monnaie ?? this.monnaie,
      pinCode: pinCode ?? this.pinCode,
      hasAccesVie: hasAccesVie ?? this.hasAccesVie,
      dateInscription: dateInscription ?? this.dateInscription,
      onboardingVu: onboardingVu ?? this.onboardingVu,
      notificationsActivees: notificationsActivees ?? this.notificationsActivees,
      dernierConnexion: dernierConnexion ?? this.dernierConnexion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cleActivee: cleActivee ?? this.cleActivee,
    );
  }
}