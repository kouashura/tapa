// lib/data/repositories/savings_repository_impl.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/i_savings_repository.dart';
import '../models/models.dart';
import '../datasources/remote/firebase/firebase_firestore_datasource.dart';
import '../../core/errors/failure.dart';
import '../../core/errors/error_handler.dart';
import '../../core/utils/logger.dart';

/// Implémentation du repository des épargnes
class SavingsRepositoryImpl implements ISavingsRepository {
  final FirebaseFirestoreDatasource _firestoreDatasource;

  SavingsRepositoryImpl({
    FirebaseFirestoreDatasource? firestoreDatasource,
  }) : _firestoreDatasource = firestoreDatasource ?? FirebaseFirestoreDatasource();

  // ============================================
  // OBJECTIFS D'ÉPARGNE
  // ============================================

  @override
  Stream<List<SavingsGoalModel>> getUserGoals(String uid) {
    return _firestoreDatasource.listenToSavingsGoals(uid).map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return SavingsGoalModel(
          id: doc.id,
          uid: data['uid'] ?? '',
          nom: data['nom'] ?? '',
          montantCible: (data['montantCible'] as num?)?.toDouble() ?? 0,
          montantActuel: (data['montantActuel'] as num?)?.toDouble() ?? 0,
          dateLimite: (data['dateLimite'] as Timestamp?)?.toDate(),
          walletId: data['walletId'] ?? '',
          estAtteint: data['estAtteint'] ?? false,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    });
  }

  @override
  Future<List<SavingsGoalModel>> getGoalsOnce(String uid) async {
    try {
      return await _firestoreDatasource.getSavingsGoals(uid);
    } catch (e) {
      Logger.error('❌ Erreur récupération objectifs: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<void> addGoal(SavingsGoalModel goal) async {
    try {
      await _firestoreDatasource.saveSavingsGoal(goal);
      Logger.info('📝 Objectif ajouté: ${goal.nom}');
    } catch (e) {
      Logger.error('❌ Erreur ajout objectif: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<void> updateGoal(SavingsGoalModel goal) async {
    try {
      await _firestoreDatasource.saveSavingsGoal(goal);
      Logger.info('📝 Objectif mis à jour: ${goal.nom}');
    } catch (e) {
      Logger.error('❌ Erreur mise à jour objectif: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    try {
      await _firestoreDatasource.deleteSavingsGoal(goalId);
      Logger.info('🗑️ Objectif supprimé: $goalId');
    } catch (e) {
      Logger.error('❌ Erreur suppression objectif: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  // ============================================
  // ÉPARGNE PROGRAMMÉE
  // ============================================

  @override
  Stream<List<EpargneProgrammeeModel>> getUserEpargne(String uid) {
    // ✅ Créer un Stream à partir de getEpargneProgrammee
    return Stream.fromFuture(_firestoreDatasource.getEpargneProgrammee(uid))
        .asBroadcastStream();
  }

  @override
  Future<List<EpargneProgrammeeModel>> getEpargneOnce(String uid) async {
    try {
      return await _firestoreDatasource.getEpargneProgrammee(uid);
    } catch (e) {
      Logger.error('❌ Erreur récupération épargne programmée: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<void> addEpargne(EpargneProgrammeeModel epargne) async {
    try {
      await _firestoreDatasource.saveEpargneProgrammee(epargne);
      Logger.info('📝 Épargne programmée ajoutée: ${epargne.titre}');
    } catch (e) {
      Logger.error('❌ Erreur ajout épargne programmée: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<void> updateEpargne(EpargneProgrammeeModel epargne) async {
    try {
      await _firestoreDatasource.saveEpargneProgrammee(epargne);
      Logger.info('📝 Épargne programmée mise à jour: ${epargne.titre}');
    } catch (e) {
      Logger.error('❌ Erreur mise à jour épargne programmée: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<void> deleteEpargne(String epargneId) async {
    try {
      await _firestoreDatasource.deleteEpargneProgrammee(epargneId);
      Logger.info('🗑️ Épargne programmée supprimée: $epargneId');
    } catch (e) {
      Logger.error('❌ Erreur suppression épargne programmée: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<void> effectuerDepot(String epargneId, double montant) async {
    try {
      final epargnes = await _firestoreDatasource.getEpargneProgrammee(epargneId);
      if (epargnes.isEmpty) {
        throw DatabaseFailure(
          message: 'Épargne programmée non trouvée.',
          code: 'EPARGNE_NOT_FOUND',
        );
      }

      final epargne = epargnes.first;
      final updatedEpargne = EpargneProgrammeeModel(
        id: epargne.id,
        uuid: epargne.uuid,
        utilisateurId: epargne.utilisateurId,
        titre: epargne.titre,
        montantObjectif: epargne.montantObjectif,
        frequence: epargne.frequence,
        duree: epargne.duree,
        montantParDepot: epargne.montantParDepot,
        portefeuilleId: epargne.portefeuilleId,
        dateCreation: epargne.dateCreation,
        dateFinPrevue: epargne.dateFinPrevue,
        montantEpargne: epargne.montantEpargne + montant,
        verrouille: epargne.verrouille,
        codeDeverrouillage: epargne.codeDeverrouillage,
        termine: epargne.termine,
      );

      await _firestoreDatasource.saveEpargneProgrammee(updatedEpargne);
      Logger.info('💰 Dépôt effectué: $montant sur ${epargne.titre}');
    } catch (e) {
      Logger.error('❌ Erreur dépôt: $e');
      throw ErrorHandler().handleException(e);
    }
  }
}
