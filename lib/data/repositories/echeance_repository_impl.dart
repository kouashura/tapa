// lib/data/repositories/echeance_repository_impl.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/i_echeance_repository.dart';
import '../models/models.dart';  // ✅ Utiliser models.dart
import '../datasources/remote/firebase/firebase_firestore_datasource.dart';
import '../../core/errors/failure.dart';
import '../../core/errors/error_handler.dart';
import '../../core/utils/logger.dart';

/// Implémentation du repository des échéances
class EcheanceRepositoryImpl implements IEcheanceRepository {
  final FirebaseFirestoreDatasource _firestoreDatasource;

  EcheanceRepositoryImpl({
    FirebaseFirestoreDatasource? firestoreDatasource,
  }) : _firestoreDatasource = firestoreDatasource ?? FirebaseFirestoreDatasource();

  @override
  Stream<List<EcheanceModel>> getUserEcheances(String uid) {
    return _firestoreDatasource.listenToEcheances(uid).map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return EcheanceModel(
          id: doc.id,
          uid: data['uid'] ?? '',
          titre: data['titre'] ?? '',
          description: data['description'] ?? '',
          montant: (data['montant'] as num?)?.toDouble() ?? 0,
          dateEcheance: (data['dateEcheance'] as Timestamp?)?.toDate() ?? DateTime.now(),
          type: data['type'] ?? 'unique',
          statut: data['statut'] ?? 'en_attente',
          descriptionRecurrence: data['descriptionRecurrence'] ?? '',
          descriptionRappel: data['descriptionRappel'] ?? '',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    });
  }

  @override
  Future<List<EcheanceModel>> getEcheancesOnce(String uid) async {
    try {
      return await _firestoreDatasource.getEcheances(uid);  // ✅ Retourne List<EcheanceModel>
    } catch (e) {
      Logger.error('❌ Erreur récupération échéances: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<void> addEcheance(EcheanceModel echeance) async {
    try {
      await _firestoreDatasource.saveEcheance(echeance);
      Logger.info('📝 Échéance ajoutée: ${echeance.titre}');
    } catch (e) {
      Logger.error('❌ Erreur ajout échéance: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<void> updateEcheance(EcheanceModel echeance) async {
    try {
      await _firestoreDatasource.saveEcheance(echeance);
      Logger.info('📝 Échéance mise à jour: ${echeance.titre}');
    } catch (e) {
      Logger.error('❌ Erreur mise à jour échéance: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<void> deleteEcheance(String echeanceId) async {
    try {
      await _firestoreDatasource.deleteEcheance(echeanceId);
      Logger.info('🗑️ Échéance supprimée: $echeanceId');
    } catch (e) {
      Logger.error('❌ Erreur suppression échéance: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<void> marquerPayee(String echeanceId) async {
    try {
      final echeances = await _firestoreDatasource.getEcheances(echeanceId);
      if (echeances.isEmpty) {
        throw DatabaseFailure(
          message: 'Échéance non trouvée.',
          code: 'ECHEANCE_NOT_FOUND',
        );
      }

      final echeance = echeances.first;

      final updatedEcheance = EcheanceModel(
        id: echeance.id,
        uid: echeance.uid,
        titre: echeance.titre,
        description: echeance.description,
        montant: echeance.montant,
        dateEcheance: echeance.dateEcheance,
        type: echeance.type,
        statut: 'payee',
        descriptionRecurrence: echeance.descriptionRecurrence,
        descriptionRappel: echeance.descriptionRappel,
        createdAt: echeance.createdAt,
        updatedAt: DateTime.now(),
      );

      await _firestoreDatasource.saveEcheance(updatedEcheance);
      Logger.info('✅ Échéance marquée comme payée: ${echeance.titre}');
    } catch (e) {
      Logger.error('❌ Erreur marquage payée: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<List<EcheanceModel>> getEcheancesEnRetard(String uid) async {
    try {
      final echeances = await _firestoreDatasource.getEcheances(uid);
      return echeances.where((e) => e.estEnRetard).toList();  // ✅ Retourne List<EcheanceModel>
    } catch (e) {
      Logger.error('❌ Erreur récupération échéances en retard: $e');
      throw ErrorHandler().handleException(e);
    }
  }
}