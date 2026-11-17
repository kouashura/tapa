import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/logger.dart';

/// Stream temps réel sur tous les contrats SONAM.
final adminSonamContractsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('sonam_contracts')
      .orderBy('dateSouscription', descending: true)
      .snapshots()
      .map((snap) {
    return snap.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        ...data,
      };
    }).toList();
  });
});

/// Filtre côté client (en attente / actif / racheté / rejeté).
class AdminSonamFilter {
  static const String tous = 'tous';
  static const String enAttente = 'En attente de paiement';
  static const String actif = 'Actif';
  static const String rachete = 'Racheté';
  static const String rejete = 'Rejeté';

  static List<String> get values =>
      [tous, enAttente, actif, rachete, rejete];
}

/// Provider de filtre (StateProvider simple).
final adminSonamFilterProvider =
    StateProvider<String>((ref) => AdminSonamFilter.tous);

/// Contrats filtrés selon le filtre actif.
final adminSonamFilteredProvider =
    Provider<List<Map<String, dynamic>>>((ref) {
  final contracts = ref.watch(adminSonamContractsProvider).valueOrNull ?? [];
  final filter = ref.watch(adminSonamFilterProvider);
  if (filter == AdminSonamFilter.tous) return contracts;
  return contracts.where((c) => c['statut'] == filter).toList();
});

/// Provider des stats SONAM.
final adminSonamStatsProvider = Provider<AdminSonamStats>((ref) {
  final contracts = ref.watch(adminSonamContractsProvider).valueOrNull ?? [];
  return AdminSonamStats.fromContracts(contracts);
});

class AdminSonamStats {
  final int total;
  final int enAttente;
  final int actifs;
  final int rachetes;
  final int rejetes;
  final double montantTotalActif;

  const AdminSonamStats({
    this.total = 0,
    this.enAttente = 0,
    this.actifs = 0,
    this.rachetes = 0,
    this.rejetes = 0,
    this.montantTotalActif = 0,
  });

  factory AdminSonamStats.fromContracts(List<Map<String, dynamic>> contracts) {
    int enAttente = 0, actifs = 0, rachetes = 0, rejetes = 0;
    double montantActif = 0;
    for (final c in contracts) {
      final statut = c['statut']?.toString() ?? '';
      switch (statut) {
        case 'En attente de paiement':
          enAttente++;
          break;
        case 'Actif':
          actifs++;
          montantActif += (c['totalVerse'] as num?)?.toDouble() ?? 0;
          break;
        case 'Racheté':
          rachetes++;
          break;
        case 'Rejeté':
          rejetes++;
          break;
      }
    }
    return AdminSonamStats(
      total: contracts.length,
      enAttente: enAttente,
      actifs: actifs,
      rachetes: rachetes,
      rejetes: rejetes,
      montantTotalActif: montantActif,
    );
  }
}

/// Actions admin sur les contrats SONAM.
class AdminSonamActions {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> valider(String contractId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return false;

      await _db.collection('sonam_contracts').doc(contractId).update({
        'statut': 'Actif',
        'validePar': uid,
        'dateValidation': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Logger.success('Contrat SONAM $contractId validé');
      return true;
    } catch (e) {
      Logger.error('Erreur validation SONAM: $e');
      return false;
    }
  }

  Future<bool> rejeter(String contractId, String motif) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return false;

      await _db.collection('sonam_contracts').doc(contractId).update({
        'statut': 'Rejeté',
        'motifRejet': motif,
        'rejetePar': uid,
        'dateRejet': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Logger.success('Contrat SONAM $contractId rejeté: $motif');
      return true;
    } catch (e) {
      Logger.error('Erreur rejet SONAM: $e');
      return false;
    }
  }
}

final adminSonamActionsProvider =
    Provider<AdminSonamActions>((ref) => AdminSonamActions());
